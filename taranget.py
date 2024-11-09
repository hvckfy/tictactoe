#taranget.py

import tarantool

# Настроим параметры подключения
host = 'localhost'  # замените на адрес вашего сервера Tarantool
port =              # стандартный порт Tarantool
username =          # ваш логин
password =          # ваш пароль
connection = tarantool.connect(host, port, user=username, password=password)

def startgame(playerID):
    result = connection.call('FindGame', [playerID])
    return result[0]

def endgame(playerID):
    result = connection.call('EndGame', [playerID])
    return result[0]

def getsecondid(playerID):
    result = connection.call('GetSecondPlayerID', [playerID])
    return result[0]

def setcommand(playerID, row, col):
    result = connection.call('set', [playerID,row,col])
    return result[0]