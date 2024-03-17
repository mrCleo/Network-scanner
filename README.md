# Network-scanner
Welcome to the Network Scanner and Weak Password Checker Tool
Getting Started:
1. Open the terminal in your computer.
2. Change the directory to where the script is located using 'cd /path/to/script'.
3. Before running the script, ensure it has execution permissions:
   - Run 'chmod +x network_scanner.sh' to make it executable.

How to Run the Script:
- Type './network_scanner.sh' and press Enter.
- The script will guide you with prompts. Just follow them!

What Happens in the Script?
1. **User Input**: You'll enter details like the network address to scan and choose between a Basic or Full scan.
2. **Password List**: Decide if you want to use a built-in list of common passwords or provide your own list for the scan.
3. **Scanning**: The script scans the network, checking for open ports and, depending on your scan choice, for vulnerabilities or weak passwords.
4. **Results**: After the scan, you'll see a summary of findings. You can also search through these results and save them into a zip file.

Understanding Scan Types:
- **Basic Scan**: Checks for open ports and identifies services running on them.
- **Full Scan**: Includes everything in Basic, plus checks for vulnerabilities using NSE scripts and attempts to identify weak passwords.

After Completion:
- The script saves all scan results in the specified output directory and creates a zip file with these results for easy access.

Troubleshooting:
- If you encounter permission errors, ensure you've made the script executable with 'chmod +x'.
- For any issues with scanning or if the script doesn't run, check your network connection and input details carefully.

This tool aims to make network scanning accessible, no prior experience needed. Enjoy exploring and securing your network!
