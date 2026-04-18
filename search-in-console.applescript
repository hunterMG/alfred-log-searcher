on run argv
	
	-- 1?? Get search term from Alfred
	set searchWord to ""
	if (count of argv) > 0 then
		set searchWord to item 1 of argv
	end if
	
	-- 2?? Get log directory from Alfred env variable
	set targetFolderPOSIX to system attribute "logDir"
	if targetFolderPOSIX is "" then
		display notification "Environment variable 'logDir' not set." with title "Alfred"
		return
	end if
	
	-- Normalize trailing slash
	if targetFolderPOSIX ends with "/" then
		set targetFolderPOSIX to text 1 thru -2 of targetFolderPOSIX
	end if
	
	-- 3?? Find newest file by creation time (birth time)
	try
		set newestFilePOSIX to do shell script "ls -tU -1 " & quoted form of targetFolderPOSIX & " | head -n 1"
	on error errMsg
		display notification errMsg with title "Directory Error"
		return
	end try
	
	if newestFilePOSIX is "" then
		display notification "No files found in directory." with title "Alfred"
		return
	end if
	
	set fullPath to targetFolderPOSIX & "/" & newestFilePOSIX
	
	-- 4?? Open file directly in Console (prevents double window)
	do shell script "open -a Console " & quoted form of fullPath
	
	-- 5?? Wait until Console is frontmost (deterministic)
	tell application "System Events"
		repeat until (exists process "Console") and (frontmost of process "Console" is true)
			delay 0.05
		end repeat
	end tell
	
	-- Small UI settle delay
	delay 0.2
	
	-- 6?? Trigger ??F (Find)
	tell application "System Events"
		keystroke "f" using {command down, option down}
	end tell
	
	delay 0.5
	
	-- 7?? Insert search term via clipboard (safe for special characters)
	if searchWord is not "" then
		set oldClipboard to the clipboard
		set the clipboard to searchWord
		
		tell application "System Events"
			keystroke "v" using {command down}
		end tell
		
		delay 0.05
		set the clipboard to oldClipboard
	end if
	
end run
