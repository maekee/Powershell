# Expanding variables inside '' to avoid escape characters
$title = "smart"
$message = 'You are so "$title"'
$message = $ExecutionContext.InvokeCommand.ExpandString($message) 
