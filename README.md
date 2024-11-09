This is easy project made to play tictactoe online with friends, working version: t.me/tictactoeingbot
It use python for server and tarantool for database

Follow these steps to set up your Tarantool instance:

    Place the configuration file you received in the directory /etc/tarantool/instances.available/.
    
    Create a directory for your instance:

    mkdir /var/tarantool_tictactoestorage_shard1

    Inside this directory, create the following subdirectories: snaps and xlogs. Also, place your tictactoestorage.lua file in this directory:

    mkdir /var/tarantool_tictactoestorage_shard1/snaps
    mkdir /var/tarantool_tictactoestorage_shard1/xlogs
    cp /path/to/your/tictactoestorage.lua /var/tarantool_tictactoestorage_shard1/

    place tarantool_tictactoestorage.grants.lua ext to tictactoestorage.lua:

    cp /path/to/your/grants_section.lua /var/tarantool_tictactoestorage_shard1/tarantool_tictactoestorage.grants.lua

    Change the permissions for the directory and its contents:

    chmod 777 -R /var/tarantool_tictactoestorage_shard1/

Managing the Tarantool Instance

After completing the setup, you can manage your Tarantool instance with the following commands:

    Check the status of the instance:

    systemctl status tarantool@tarantool_tictactoestorage_shard1

    Reload the instance configuration:

    systemctl reload tarantool@tarantool_tictactoestorage_shard1

    Enable the instance to start on boot:

    systemctl enable tarantool@tarantool_tictactoestorage_shard1

    Start the Tarantool instance:

    systemctl start tarantool@tarantool_tictactoestorage_shard1

Once you complete these steps, your Tarantool instance should start successfully. 

Configurate tictactoe.sevice file for next steps:
Step 1: Create a Virtual Environment
      ```
      Create a virtual environment and name it as you prefer. You can do this using the following command:
      
      python3 -m venv /path/to/your/venv
      
Step 2: Activate the Virtual Environment

      Activate the virtual environment using:
      
      source /path/to/your/venv/bin/activate
      
Step 3: Install Required Libraries

    Once the virtual environment is activated, install the necessary libraries:

    pip install pytelegrambotapi tarantool

Step 4: Create the systemd Service File

    Create a service file named tictactoebot.service in the /etc/systemd/system/ directory with the following content:

    [Unit]
    Description=tictactoebot
    After=network.target
    [Service]
    User =root
    ExecStart=/bin/bash -c "source /path/to/your/venv/bin/activate && python3 /path/to/your/server.py"
    Restart=always
    RestartSec=10
    [Install]
    WantedBy=multi-user.target


Follow these steps to set up systemd for automatic startup:
Step 1: Move the Service File

    First, move the tictactoe.service file to the systemd directory for user services:

    sudo mv /path/to/tictactoe.service /etc/systemd/system/

Step 2: Configure Autostart

    Open the service file for editing if necessary:

    sudo nano /etc/systemd/system/tictactoe.service

    Ensure that the correct parameters are specified, such as ExecStart, User , and others.
    After making any necessary changes, save the file and exit the editor.

Step 3: Reload systemd Configuration


    After moving or modifying the service file, you need to reload the systemd configuration:
    
    sudo systemctl daemon-reload


Step 4: Enable the Service to Start at Boot

    Now you can enable the service to start automatically when the system boots:
    
    sudo systemctl enable tictactoe.service

Step 5: Start the Service

    If you want to start the service immediately, run:
    
    sudo systemctl start tictactoe.service

Step 6: Check the Service Status

    To ensure that the service is running correctly, execute:
    
    sudo systemctl status tictactoe.service

Step 7: View Logs

    If the service fails to start or encounters errors, you can view the logs using:
    
    journalctl -u tictactoe.service

