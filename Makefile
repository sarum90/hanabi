
default: rem-run

test:
	nodeunit test/gameTest.coffee

run:
	coffee server.coffee

rem-run:
	tmux send-keys -t 2 C-c "coffee server.coffee" C-m

.PHONY: test default run rem-run
