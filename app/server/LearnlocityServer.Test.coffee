v = require("./VocabServer.coffee")

describe 'Login', ->
	describe 'getValidationErrors', ->
		it 'returns error when userNameOrEmail empty', ->
			cmd = new v.Login(null, "email@email.com")
			runTest(cmd, "Username or Email cannot be empty")
		it 'returns error when password empty', ->
			cmd = new v.Login("jogo", "")
			runTest(cmd, "Password cannot be empty")

describe 'AccountRegister', ->
	describe 'getValidationErrors', ->
		it 'returns error when userName empty', ->
			cmd = new v.AccountRegister(null, "email@email.com",
				"password", "password")
			runTest(cmd, "userName cannot be empty")
		
		it 'returns error when userName exceeds max', ->
			name = '01234567890123456789012345678901234567890123456789x'
			cmd = new v.AccountRegister(name, "email@email.com",
				"password", "password")
			runTest(cmd, "userName cannot be more than 50 characters")

		it 'returns error when userName under min', ->
			name = '012'
			cmd = new v.AccountRegister(name, "email@email.com",
				"password", "password")
			runTest(cmd, "userName cannot be fewer than 4 characters")			

describe 'VocabServer', ->
	describe 'Login', ->
		it 'returns true for registered user', ->
			cmd = new v.Login("jogo", "jogo@shugh.com")
			svr = new v.VocabServer
			rv = svr.send(cmd)
			rv.should.equal(true)
		# TODO add tests for unregistered users
		# TODO add tests for Registration itself for that matter

	describe 'ChallengeCreate', ->
		it 'returns challenge for valid command', ->
			cmd = new v.ChallengeCreate("jogo", "Jogo Game")
			svr = new v.VocabServer
			rv = svr.send(cmd)
			rv.userName.should.equal("jogo")
			rv.name.should.equal("Jogo Game")
			score = rv.scoreDetails()
			score.length.should.equal(1)
			score[0][0].should.equal("jogo")

	describe 'ChallengeJoin', ->
		it 'returns true when new user joins existing challenge', ->
			cmd = new v.ChallengeCreate("jogo", "Jogo Game")
			svr = new v.VocabServer
			challenge = svr.send(cmd)
			cmd = new v.ChallengeJoin("mogo", "Jogo Game")
			rv = svr.send(cmd)
			rv.should.equal(true)
			score = challenge.scoreDetails()
			score.length.should.equal(2)
			score[0][0].should.equal("jogo")		
			score[1][0].should.equal("mogo")
		it 'returns false when new user joins non-existent challenge', ->
			cmd = new v.ChallengeJoin("mogo", "Jogo Game")
			svr = new v.VocabServer
			challenge = svr.send(cmd)
			challenge.should.equal(false)

	describe 'ChallengeSubmitAnswer', ->
		it 'returns true when correct answer for first question', ->
			userName = "jogo"
			gameName = "Jogo Game"
			cmd = new v.ChallengeCreate(userName, gameName)
			svr = new v.VocabServer
			challenge = svr.send(cmd)
			answer0 = challenge.questionByIndex(0)
			correctWord = answer0[0].word
			cmd = new v.ChallengeSubmitAnswer(gameName, userName, 0, correctWord)
			rv = svr.send(cmd)
			rv.should.equal(true)

	describe 'ChallengeSubmitAnswer', ->
		it 'returns false when incorrect answer for first question', ->
			userName = "jogo"
			gameName = "Jogo Game"
			cmd = new v.ChallengeCreate(userName, gameName)
			svr = new v.VocabServer
			challenge = svr.send(cmd)
			answer0 = challenge.questionByIndex(0)
			correctWord = answer0[0].word
			cmd = new v.ChallengeSubmitAnswer(gameName, userName, 0, correctWord + correctWord)
			rv = svr.send(cmd)
			rv.should.equal(false)			

	describe 'ChallengeSubmitAnswer', ->
		it 'returns true for ten correct answers in a row by a single player', ->
			userName = "jogo"
			gameName = "Jogo Game"
			cmd = new v.ChallengeCreate(userName, gameName)
			svr = new v.VocabServer
			challenge = svr.send(cmd)
			for i in [0..9]
				answer = challenge.questionByIndex(i)
				correctWord = answer[0].word				
				cmd = new v.ChallengeSubmitAnswer(gameName, userName, 
					i, correctWord)
				rv = svr.send(cmd)
				rv.should.equal(true)

	describe 'ChallengeSubmitAnswer', ->
		it 'returns true for ten correct answers in a row by two players', ->
			userName = "jogo"
			gameName = "Jogo Game"
			player2 = "mogo"
			cmd = new v.ChallengeCreate(userName, gameName)
			svr = new v.VocabServer
			challenge = svr.send(cmd)
			cmd = new v.ChallengeJoin(player2, gameName)
			svr.send(cmd)

			for i in [0..9]
				answer = challenge.questionByIndex(i)
				correctWord = answer[0].word
				
				cmd = new v.ChallengeSubmitAnswer(gameName, userName, 
					i, correctWord)
				rv = svr.send(cmd)
				rv.should.equal(true)

				cmd = new v.ChallengeSubmitAnswer(gameName, player2, 
					i, correctWord)					
				rv = svr.send(cmd)
				rv.should.equal(true)

	describe 'ChallengeScoreDetails after two players answer ten questions', ->
		gameName = "Jogo Game"
		player1 = "jogo"
		player2 = "mogo"
		cmd = new v.ChallengeCreate(player1, gameName)
		svr = new v.VocabServer
		challenge = svr.send(cmd)
		cmd = new v.ChallengeJoin(player2, gameName)
		svr.send(cmd)

		for i in [0..9]
			answer = challenge.questionByIndex(i)
			correctWord = answer[0].word
			
			cmd = new v.ChallengeSubmitAnswer(gameName, player1, 
				i, correctWord)
			rv = svr.send(cmd)

			cmd = new v.ChallengeSubmitAnswer(gameName, player2, 
				i, correctWord)					
			rv = svr.send(cmd)

		it 'returns false when player1 attempts another answer', ->
			cmd = new v.ChallengeSubmitAnswer(gameName, player1,
				10, "bogus")
			rv = svr.send(cmd)
			rv.should.equal(false)

		it 'returns false when player2 attempts another answer', ->
			cmd = new v.ChallengeSubmitAnswer(gameName, player2,
				10, "bogus")
			rv = svr.send(cmd)
			rv.should.equal(false)
		
		it 'returns correct scores for both players', ->
			answers = (challenge.questionByIndex(i) for i in [0..9])		
			cmd = new v.ChallengeScoreDetails(gameName)
			scoreDetails = svr.send(cmd)
			player1ans = scoreDetails[0][1]
			player2ans = scoreDetails[1][1]
			for i in [0..9]
				answer = answers[i]
				correctWord = answer[0].word				
				correctWord.should.equal(player1ans[i].answer)
				correctWord.should.equal(player2ans[i].answer)

runTest = (cmd, expectedMessage) ->
	e = cmd.getValidationErrors()
	e.length.should.equal(1)
	e[0].should.equal(expectedMessage)