#AutoIt3Wrapper_Icon=shell32.dll,14
#AutoIt3Wrapper_Res_Description=Lost Cry Ai Client
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <InetConstants.au3>
#include <JSON.au3> ; Требуется библиотека JSON для разбора ответа

; ==============================================================================
; НАСТРОЙКИ
; ==============================================================================
; ВСТАВЬТЕ СЮДА ВАШ НОВЫЙ КЛЮЧ ПОСЛЕ ТОГО, КАК ОТОЗВЕТЕ СТАРЫЙ
Global Const $API_KEY = "ВАШ_НОВЫЙ_КЛЮЧ_ЗДЕСЬ" 
Global Const $API_URL = "https://openrouter.ai/api/v1/chat/completions"
Global Const $MODEL_NAME = "mistralai/mistral-7b-instruct:free" ; Пример бесплатной модели

; ==============================================================================
; СОЗДАНИЕ GUI
; ==============================================================================
Global $hGUI = GUICreate("Lost Cry Ai", 600, 500, -1, -1, BitOR($WS_MINIMIZEBOX, $WS_SYSMENU))
GUISetBkColor(0x1a1a1a) ; Темный фон

; Заголовок
Global $hLabelTitle = GUICtrlCreateLabel("Lost Cry Ai", 20, 15, 560, 30)
GUICtrlSetFont(-1, 24, 800, 0, "Consolas")
GUICtrlSetColor(-1, 0x00ff99)

; Поле вывода ответа (Лог)
Global $hOutput = GUICtrlCreateEdit("", 20, 60, 560, 300, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
GUICtrlSetFont(-1, 10, 400, 0, "Consolas")
GUICtrlSetBkColor(-1, 0x2b2b2b)
GUICtrlSetColor(-1, 0xe0e0e0)

; Поле ввода запроса
Global $hInput = GUICtrlCreateInput("", 20, 380, 480, 30)
GUICtrlSetFont(-1, 11, 400, 0, "Segoe UI")
GUICtrlSetHint(-1, "Введите ваш запрос здесь...")

; Кнопка отправки
Global $hBtnSend = GUICtrlCreateButton("ОТПРАВИТЬ", 510, 380, 70, 30)
GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0x00cc7a)
GUICtrlSetColor(-1, 0xffffff)

; Статус бар
Global $hStatus = GUICtrlCreateLabel("Готов к работе", 20, 430, 560, 20)
GUICtrlSetColor(-1, 0x888888)

GUISetState(@SW_SHOW)

; ==============================================================================
; ОСНОВНОЙ ЦИКЛ
; ==============================================================================
While True
    $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            Exit
        Case $hBtnSend
            SendRequest()
    EndSwitch
WEnd

; ==============================================================================
; ФУНКЦИИ
; ==============================================================================

Func SendRequest()
    Local $sUserInput = GUICtrlRead($hInput)
    
    If StringStripWS($sUserInput, 8) = "" Then
        GUICtrlSetData($hStatus, "Ошибка: Введите текст запроса")
        Return
    EndIf

    If $API_KEY = "ВАШ_НОВЫЙ_КЛЮЧ_ЗДЕСЬ" Then
        GUICtrlSetData($hOutput, GUICtrlRead($hOutput) & "> ОШИБКА: API ключ не настроен в коде!" & @CRLF)
        GUICtrlSetData($hStatus, "Требуется настройка API ключа")
        Return
    EndIf

    GUICtrlSetData($hStatus, "Отправка запроса...")
    GUICtrlSetData($hBtnSend, "Ждите...")
    GUICtrlSetState($hBtnSend, $GUI_DISABLE)

    ; Формирование JSON тела запроса
    Local $sJsonPayload = '{"model": "' & $MODEL_NAME & '", "messages": [{"role": "user", "content": "' _
                          & StringReplace(StringReplace($sUserInput, '"', '\"'), @CRLF, '\n') _
                          & '"}]}'

    ; Настройка заголовков
    Local $sHeaders = "Content-Type: application/json" & @CRLF & "Authorization: Bearer " & $API_KEY

    ; Отправка запроса
    Local $sResponse = InetRead($API_URL, $INET_FORCERELOAD)
    
    ; Примечание: InetRead в базовом AutoIt не поддерживает кастомные заголовки POST напрямую без объекта WinHttp.
    ; Для полноценной работы с API необходим объект WinHttp.WinHttpRequest.5.1 ниже реализация через него.
    
    Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
    $oHTTP.Open("POST", $API_URL, False)
    $oHTTP.SetRequestHeader("Content-Type", "application/json")
    $oHTTP.SetRequestHeader("Authorization", "Bearer " & $API_KEY)
    $oHTTP.SetRequestHeader("HTTP-Referer", "https://lostcryai.local") ; Требуется OpenRouter
    $oHTTP.SetRequestHeader("X-Title", "Lost Cry Ai") ; Требуется OpenRouter
    
    $oHTTP.Send($sJsonPayload)
    
    Local $sRawResponse = $oHTTP.ResponseText
    Local $iStatusCode = $oHTTP.Status

    GUICtrlSetData($hBtnSend, "ОТПРАВИТЬ")
    GUICtrlSetState($hBtnSend, $GUI_ENABLE)

    If $iStatusCode = 200 Then
        ; Парсинг JSON (упрощенный, так как стандартная библиотека JSON может отсутствовать)
        ; Попытка извлечь content вручную через регулярные выражения для надежности без внешних UDF
        Local $sContent = StringRegExpReplace($sRawResponse, '.*"content"\s*:\s*"([^"]*)".*', "$1")
        
        ; Декодирование простых escape-последовательностей
        $sContent = StringReplace($sContent, '\n', @CRLF)
        $sContent = StringReplace($sContent, '\"', '"')
        
        GUICtrlSetData($hOutput, GUICtrlRead($hOutput) & "> Вы: " & $sUserInput & @CRLF & "> AI: " & $sContent & @CRLF & @CRLF)
        GUICtrlSetData($hStatus, "Ответ получен успешно")
    Else
        GUICtrlSetData($hOutput, GUICtrlRead($hOutput) & "> Ошибка API (" & $iStatusCode & "): " & $sRawResponse & @CRLF)
        GUICtrlSetData($hStatus, "Ошибка соединения")
    EndIf
    
    GUICtrlSetData($hInput, "")
    GUICtrlSetState($hInput, $GUI_FOCUS)
EndFunc
