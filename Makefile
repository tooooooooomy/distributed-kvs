status:
	pgrep -f my-app.rb
	ss -tapn | grep -e '3000\|3001\|3002'

up:
	nohup bundle exec ruby my-app.rb -p 3000 >> log.txt 2>&1 &
	nohup bundle exec ruby my-app.rb -p 3001 >> log.txt 2>&1 &
	nohup bundle exec ruby my-app.rb -p 3002 >> log.txt 2>&1 &

down:
	pkill -9 -f my-app.rb

restart: up down
