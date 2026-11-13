using System.Runtime.InteropServices;
using Windows.Media;
using Windows.Media.Audio;
using Windows.Media.Capture;
using Windows.Media.Capture.Frames;
using Windows.Media.MediaProperties;
using Windows.Media.Render;
using Windows.Storage;

namespace Lumo.UI;

[ComImport, Guid("5B0D3235-4DBA-4D44-865E-8F1D0E4FD04D"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
unsafe interface IMemoryBufferByteAccess { void GetBuffer(out byte* buffer, out uint capacity); }

/// <summary>Запись голосового: микрофон → файл m4a (AAC) + уровни громкости для «волны» (40 столбиков 0…31, как на телефонах)</summary>
public sealed class VoiceRecorder
{
    AudioGraph? graph;
    AudioFileOutputNode? fileNode;
    AudioFrameOutputNode? frameNode;
    AudioDeviceInputNode? input;
    StorageFile? file;
    readonly List<int> levels = new();
    float peak;
    int quanta;
    DateTime started;
    public double Seconds => (DateTime.UtcNow - started).TotalSeconds;
    public event Action<float>? Level;

    public async Task<string?> Start()
    {
        try
        {
            var r = await AudioGraph.CreateAsync(new AudioGraphSettings(AudioRenderCategory.Speech));
            if (r.Status != AudioGraphCreationStatus.Success) return "Не удалось открыть звук";
            graph = r.Graph;
            var ir = await graph.CreateDeviceInputNodeAsync(MediaCategory.Speech);
            if (ir.Status != AudioDeviceNodeCreationStatus.Success)
                return ir.Status == AudioDeviceNodeCreationStatus.AccessDenied ? "Нет доступа к микрофону: разрешите его в Параметрах Windows → Конфиденциальность → Микрофон" : "Микрофон не найден";
            input = ir.DeviceInputNode;
            var dir = await StorageFolder.GetFolderFromPathAsync(Path.GetTempPath());
            file = await dir.CreateFileAsync("lumo-voice.m4a", CreationCollisionOption.GenerateUniqueName);
            var fr = await graph.CreateFileOutputNodeAsync(file, MediaEncodingProfile.CreateM4a(AudioEncodingQuality.Medium));
            if (fr.Status != AudioFileNodeCreationStatus.Success) return "Не удалось начать запись";
            fileNode = fr.FileOutputNode;
            frameNode = graph.CreateFrameOutputNode();
            input.AddOutgoingConnection(fileNode);
            input.AddOutgoingConnection(frameNode);
            graph.QuantumStarted += OnQuantum;
            levels.Clear(); peak = 0; quanta = 0;
            started = DateTime.UtcNow;
            graph.Start();
            return null;
        }
        catch (Exception e) { App.Log("voice start: " + e.Message); Dispose(); return "Не удалось начать запись"; }
    }

    unsafe void OnQuantum(AudioGraph g, object _)
    {
        try
        {
            using var frame = frameNode!.GetFrame();
            using var buf = frame.LockBuffer(AudioBufferAccessMode.Read);
            using var refc = buf.CreateReference();
            WinRT.CastExtensions.As<IMemoryBufferByteAccess>(refc).GetBuffer(out byte* data, out uint cap);
            var f = (float*)data; var n = (int)(buf.Length / 4);
            for (int i = 0; i < n; i++) { var v = Math.Abs(f[i]); if (v > peak) peak = v; }
            // каждые ~100 мс — один уровень
            if (++quanta >= 10)
            {
                quanta = 0;
                var lv = Math.Min(31, (int)(Math.Sqrt(peak) * 40));
                lock (levels) levels.Add(lv);
                Level?.Invoke(peak);
                peak = 0;
            }
        }
        catch { }
    }

    /// <summary>Остановить; путь к файлу, длительность и волна (или null, если запись пустая)</summary>
    public async Task<(string path, double dur, List<int> wave)?> Stop()
    {
        var dur = Seconds;
        try
        {
            graph?.Stop();
            if (fileNode != null) await fileNode.FinalizeAsync();
        }
        catch (Exception e) { App.Log("voice stop: " + e.Message); }
        var path = file?.Path;
        Dispose();
        if (path == null || dur < 0.6) return null;
        List<int> src;
        lock (levels) src = levels.Count == 0 ? new List<int> { 4 } : levels.ToList();
        var wave = Enumerable.Range(0, 40).Select(i => src[Math.Clamp(i * src.Count / 40, 0, src.Count - 1)]).ToList();
        return (path, dur, wave);
    }

    public void Cancel()
    {
        try { graph?.Stop(); } catch { }
        var p = file?.Path;
        Dispose();
        _ = Task.Run(async () => { await Task.Delay(500); try { if (p != null) File.Delete(p); } catch { } });
    }

    void Dispose()
    {
        try { if (graph != null) graph.QuantumStarted -= OnQuantum; graph?.Dispose(); } catch { }
        graph = null; fileNode = null; frameNode = null; input = null;
    }
}

/// <summary>Запись видеосообщения (кружка): камера и микрофон → mp4; предпросмотр — поток кадров камеры</summary>
public sealed class VideoNoteRecorder
{
    MediaCapture? mc;
    StorageFile? file;
    DateTime started;
    public double Seconds => (DateTime.UtcNow - started).TotalSeconds;
    public Windows.Media.Core.MediaSource? Preview { get; private set; }

    public async Task<string?> Open()
    {
        try
        {
            mc = new MediaCapture();
            await mc.InitializeAsync(new MediaCaptureInitializationSettings { StreamingCaptureMode = StreamingCaptureMode.AudioAndVideo });
            var src = mc.FrameSources.Values.FirstOrDefault(s => s.Info.SourceKind == MediaFrameSourceKind.Color && s.Info.MediaStreamType == Windows.Media.Capture.MediaStreamType.VideoPreview)
                      ?? mc.FrameSources.Values.FirstOrDefault(s => s.Info.SourceKind == MediaFrameSourceKind.Color);
            if (src != null) Preview = Windows.Media.Core.MediaSource.CreateFromMediaFrameSource(src);
            return null;
        }
        catch (UnauthorizedAccessException) { Close(); return "Нет доступа к камере или микрофону: разрешите их в Параметрах Windows → Конфиденциальность"; }
        catch (Exception e) { App.Log("vnote open: " + e.Message); Close(); return "Камера не найдена"; }
    }

    public async Task<string?> Start()
    {
        if (mc == null) return "Камера не открыта";
        try
        {
            var dir = await StorageFolder.GetFolderFromPathAsync(Path.GetTempPath());
            file = await dir.CreateFileAsync("lumo-round.mp4", CreationCollisionOption.GenerateUniqueName);
            var prof = MediaEncodingProfile.CreateMp4(VideoEncodingQuality.Vga);
            await mc.StartRecordToStorageFileAsync(prof, file);
            started = DateTime.UtcNow;
            return null;
        }
        catch (Exception e) { App.Log("vnote start: " + e.Message); return "Не удалось начать запись"; }
    }

    public async Task<(string path, double dur)?> Stop()
    {
        var dur = Seconds;
        try { if (mc != null) await mc.StopRecordAsync(); } catch (Exception e) { App.Log("vnote stop: " + e.Message); }
        var p = file?.Path;
        Close();
        if (p == null || dur < 0.8) return null;
        return (p, dur);
    }

    public void Close()
    {
        try { Preview?.Dispose(); } catch { }
        Preview = null;
        try { mc?.Dispose(); } catch { }
        mc = null;
    }
}
