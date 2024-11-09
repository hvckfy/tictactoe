TOKEN = 
import telebot
from telebot import types
import taranget as t

bot = telebot.TeleBot(TOKEN)

SPACE_GAMES_SESSION_ID = 0
SPACE_GAMES_STATUS = 1
SPACE_GAMES_FIELD = 2
SPACE_GAMES_METAINFO = 3
SPACE_GAMES_PLAYER1 = 4
SPACE_GAMES_PLAYER2 = 5
SPACE_GAMES_TIMESTAMP = 6

def checkwin(field):
    # Check rows
    for row in field:
        if row.count(1) == 3:
            return 1
        elif row.count(2) == 3:
            return 2

    # Check columns
    for col in range(3):
        if field[0][col] == field[1][col] == field[2][col] != 0:
            return 1 if field[0][col] == 1 else 2

    # Check diagonals
    if field[0][0] == field[1][1] == field[2][2] != 0:
        return 1 if field[0][0] == 1 else 2
    if field[0][2] == field[1][1] == field[2][0] != 0:
        return 1 if field[0][2] == 1 else 2

    # If no winner, return 0
    return False

def get_username(user_id):
    chat = bot.get_chat(user_id)
    username = chat.username
    if username:
        return f"@{username}"
    else:
        return "have no username"

def end_game(user_id):
    user_id2 = t.getsecondid(user_id)
    request = t.endgame(user_id)
    if type(request) is str:
        bot.send_message(user_id,request)
    print('endgame request =',request)
    print(user_id,user_id2)
    if user_id2:
        bot.send_message(user_id2,'Your existing game was deleted. \nUse /startgame to start a new game')

def InitKeyBoard(chat_id,text,game_tuple):

    field=game_tuple[SPACE_GAMES_FIELD]
    def GetSign(IncomeInt):
        if IncomeInt==1:
            return '❌'
        elif IncomeInt==2:
            return '⚫️ '
        else:
            return ' '

    markup = types.InlineKeyboardMarkup()
    count=1
    for i in field:
        print('print i in init:', i)
        markup.add(
            types.InlineKeyboardButton( GetSign(i[0]), callback_data=str(count)+str(1)),
            types.InlineKeyboardButton( GetSign(i[1]), callback_data=str(count)+str(2)),
            types.InlineKeyboardButton( GetSign(i[2]), callback_data=str(count)+str(3))
        )
        count+=1
    bot.send_message(chat_id, text, reply_markup=markup)

@bot.message_handler(commands=['startgame'])
def start_game(message):    
    user_id=message.chat.id
    request = t.startgame(user_id)
    print('startgame request =',request)
    if type(request) is str:
        bot.send_message(user_id,request)
    else:
        if request[SPACE_GAMES_STATUS]=='inprogress':
            bot.send_message(request[SPACE_GAMES_PLAYER1], 'Your opponent '+get_username(request[SPACE_GAMES_PLAYER2]))
            bot.send_message(request[SPACE_GAMES_PLAYER2], 'Your opponent '+get_username(request[SPACE_GAMES_PLAYER1]))
            InitKeyBoard(request[SPACE_GAMES_PLAYER1],'Your turn is first       :',request)
            InitKeyBoard(request[SPACE_GAMES_PLAYER2],'Your turn is second  :',request)
        else:
            bot.send_message(user_id,'Wait for opponent...')

@bot.message_handler(commands=['start'])
def start_game(message):    
    bot.reply_to(message,'Hello! \n/startgame - to start game,  \n/endgame - to endgame.\nYou are welcome!')

@bot.message_handler(commands=['endgame'])
def endgamecommnd(message):
    user_id=message.chat.id
    end_game(user_id)
    
@bot.callback_query_handler(func=lambda call: True)
def callback_inline(call):
    user_id=call.message.chat.id
    print(call.data)
    row=int(call.data[0])
    col=int(call.data[1])
    request=t.setcommand(user_id,row,col)
    print(request)
    PlayerWatch='Your opponents turn:'
    PLayerPlay= 'Your turn                  :'
    PlayerID=call.message.chat.id
    if type(request) is not str:
        if request[SPACE_GAMES_PLAYER1]==PlayerID and request[SPACE_GAMES_METAINFO]%2==1:
            InitKeyBoard(PlayerID,PLayerPlay,request)
            InitKeyBoard(t.getsecondid(PlayerID),PlayerWatch,request)
        elif request[SPACE_GAMES_PLAYER2]==PlayerID and request[SPACE_GAMES_METAINFO]%2==0:
            InitKeyBoard(PlayerID,PLayerPlay,request)
            InitKeyBoard(t.getsecondid(PlayerID),PlayerWatch,request)
        else:
            InitKeyBoard(t.getsecondid(PlayerID),PLayerPlay,request)
            InitKeyBoard(PlayerID,PlayerWatch,request)
        WhoWinner = checkwin(request[SPACE_GAMES_FIELD])
        if WhoWinner:
            if WhoWinner==1:
                bot.send_message(request[SPACE_GAMES_PLAYER1],'YOU WIN')
                bot.send_message(request[SPACE_GAMES_PLAYER2],'YOU LOSE')
            elif WhoWinner==2:
                bot.send_message(request[SPACE_GAMES_PLAYER2],'YOU WIN')
                bot.send_message(request[SPACE_GAMES_PLAYER1],'YOU LOSE')
            end_game(user_id)
        if request[SPACE_GAMES_METAINFO]==10:
            bot.send_message(t.getsecondid(PlayerID),'DRAW')
            bot.send_message(PlayerID,'DRAW')
            user_id2 = t.getsecondid(PlayerID)
            end_game(PlayerID)
            if user_id2:
                bot.send_message(user_id2,'Your existing game was deleted. \nUse /startgame to start a new game')

    else:
        bot.send_message(call.message.chat.id, request )
bot.polling()
