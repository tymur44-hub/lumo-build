package ru.volshebnymir.lumo.core

/** Связка со звонками: модуль звонков подключается сюда */
object CallsBridge {
    var onAttach: (String) -> Unit = {}
    var onDetach: () -> Unit = {}
    fun attach(id: String) = onAttach(id)
    fun detach() = onDetach()
}
