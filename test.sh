curl -si -d 'tommy' http://localhost:3000/name #=> success
curl -si http://localhost:3001/name;echo #=> 'tommy'
make stop-1
curl -si -d 'ujihisa' http://localhost:3000/name #=> fail
curl -si -d 'ujihisa' http://localhost:3001/name #=> success
curl -si http://localhost:3000/name;echo #=> fail
curl -si http://localhost:3001/name;echo #=> 'ujihisa'
make start-1
sleep 1
curl -si http://localhost:3000/name;echo #=> 'ujihisa', not 404
