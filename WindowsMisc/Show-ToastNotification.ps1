#The toast does not stay in systray before it goes into notification center, the notification will just show for x amount of seconds

Function Show-ToastNotification {
    param(
        $Title,
        $TopMessage,
        $LowerMessage
    )

    # Create Toast Notification template for message content
    # https://learn.microsoft.com/en-us/previous-versions/windows/apps/hh761494(v=win.10)?redirectedfrom=MSDN#text-only-templates
    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    # Convert to .NET type for XML manipuration
    $toastXml = [xml]$template.GetXml()

    # Customize the toast message
    $toastXml.GetElementsByTagName("text")[0].AppendChild($toastXml.CreateTextNode($TopMessage)) > $null
    $toastXml.GetElementsByTagName("text")[1].AppendChild($toastXml.CreateTextNode($LowerMessage)) > $null

    # Create XML object and load xml
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($toastXml.OuterXml)

    # Create Toast message
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    $toast.Tag = $Title
    $toast.Group = "MessageGroup"

    $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    # Create Notification object
    #$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($toast.Tag)

    # Show Notification by passing created toast with Toast Notification xml data
    $notifier.Show($toast);
}
