# No AI in VS Code

This tool provides a quick way to toggle AI features and connectivity in Visual Studio Code.

## Disabling AI
- Removes all extensions related to AI agents
- Disables AI-related inline suggestions
- Disables AI chat features
- Blocks internet access for VS Code
- Run VSCode without internet access (even discord rpc)

## Enabling AI
- Re-installs all removed AI extensions
- Enables inline suggestions and chat
- Re-enables internet access for VS Code

## How To Use
1. Open **PowerShell** as an Administrator.
2. Navigate to the folder containing the script.
3. Run the script by executing the following command:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\main.ps1
   ```
