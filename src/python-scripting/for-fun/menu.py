import pyfiglet
from colorama import Fore, Back, Style

def drawMenu(title, options):
    print(Fore.CYAN + "\n" + "="*40)
    print(Fore.YELLOW + f"{pyfiglet.figlet_format(title, font='slant')}")
    print(Fore.CYAN + "-"*40)
    for idx, option in enumerate(options, start=1):
        print(Fore.YELLOW + f"{idx}. {option}")
    print(Fore.CYAN + "="*40 + Fore.WHITE)
    

if __name__ == "__main__":
    while True:
        drawMenu("Test", ["Option One", "Option Two", "Option Three", "Exit"])
        choice = input("Select an option (1-4): ").strip()
        
        if choice == "1":
            print("You selected Option One")
        elif choice == "2":
            print("You selected Option Two")
        elif choice == "3":
            print("You selected Option Three")
        elif choice == "4":
            print("Goodbye!")
            break
        else:
            print("Invalid choice. Please try again.")
