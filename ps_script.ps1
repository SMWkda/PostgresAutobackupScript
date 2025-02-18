### powershell.exe -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File "C:\PS\OutlookEmailtoTG.ps1"
# https://winitpro.ru/index.php/2024/09/10/zapusk-powershell-skripta-task-scheduler/
#
#
# Указываем путь к pg_dump.exe
$pgDumpPath = "C:\Program Files\pgAdmin 4\runtime\pg_dump.exe"

# Параметры подключения
$dbHost = "192.168.0.220"
$port = "5432"
$username = "backend"
$password = "password123"  # Укажите здесь пароль от БД
$schema = "public"
$dbName = "backend"

# Путь к папке для бэкапов
$backupDir = "D:\PostgresBackups\BackupFolder123\"

# Форматируем текущую дату
$date = Get-Date -Format "yyyy-MM-dd-HH-mm"

# Формируем имя файла
$backupFileName = "database123-$date.backup" # Название архива с бэкапом
$backupFilePath = Join-Path -Path $backupDir -ChildPath $backupFileName

# Убедимся, что папка для бэкапов существует
if (-not (Test-Path -Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir
}

# Устанавливаем переменную окружения PGPASSWORD для автоматической передачи пароля
$env:PGPASSWORD = $password

# Формируем команду как массив аргументов
$pgDumpArgs = @(
    "--file=$backupFilePath"
    "--host=$dbHost"
    "--port=$port"
    "--username=$username"
    "--format=t"
    "--large-objects"
    "--no-owner"
    "--verbose"
    "--schema=$schema"
    $dbName
)

# Креды бота Telegram
$Telegramtoken = "botID:botToken" # Сюда ставим креды от тг-бота: ID и токен, в формате bot5768249291:XAHprDiuhfbdkjuhdsfsd-DASOIfdkcJ2
$Telegramchatid = "-10045223431162" # Сюда ставим ChatID от чата телеги, куда бот будет отсылать алерты

# Тело сообщения алерта в Telegram
$bodyStart = "[hp-backup][walk-master] pg_dump: walk-back-db backup started" # Сюда можно написать что угодно, по вашему вкусу
$bodyOK = "[hp-backup][walk-master] pg_dump: walk-back-db successfully saved to $backupFilePath" # Сюда тоже можно написать что угодно

# Выполняем pg_dump и отсылаем в телегу алерт о старте джобы
Invoke-RestMethod -Uri "https://api.telegram.org/$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($bodyStart)"
Write-Host "Запуск pg_dump для создания бэкапа: $backupFilePath" -ForegroundColor Green
& $pgDumpPath @pgDumpArgs

# Проверяем статус выполнения и отсылаем алерт об окончании джобы
if ($LASTEXITCODE -eq 0) {
    Write-Host "Бэкап успешно создан: $backupFilePath" -ForegroundColor Cyan
    Invoke-RestMethod -Uri "https://api.telegram.org/$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($bodyOK)"
} else {
    Write-Host "Ошибка создания бэкапа. Код ошибки: $LASTEXITCODE" -ForegroundColor Red
    Invoke-RestMethod -Uri "https://api.telegram.org/$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($LASTEXITCODE)"
}

# Удаляем переменную окружения PGPASSWORD для безопасности
Remove-Item Env:\PGPASSWORD
