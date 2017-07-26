enum PhGameState
{
	None,
	Hiding,
	Seeking,
	EndOfRound,
	EndOfGame,
}

class PhTeamScore : TeamVersusScore
{
	bool m_hiding;
	int m_score;

	PhTeamScore(uint team)
	{
		super(team);
	}

	int GetScore() override
	{
		return m_score;
	}

	int opCmp(const TeamVersusScore &in other) override
	{
		return opCmp(cast<PhTeamScore>(other));
	}

	int opCmp(const PhTeamScore &in other)
	{
		if (m_score > other.m_score) return 1;
		if (m_score < other.m_score) return -1;
		return 0;
	}
}

[GameMode]
class PropHunt : TeamVersusGameMode
{
	PhGameState m_state = PhGameState::None;
	uint m_tmStartState;

	uint m_tmLimitHiding = 5000;
	uint m_tmLimitSeeking = 10000;
	uint m_tmLimitEndOfRound = 5000;

	PhTeamScore@ m_team1;
	PhTeamScore@ m_team2;

	HUDProphunt@ m_hudProphunt;
	Blinded@ m_hudBlinded;

	PropHunt(Scene@ scene)
	{
		super(scene);

		@m_team1 = cast<PhTeamScore>(m_teamScores[0]);
		@m_team2 = cast<PhTeamScore>(m_teamScores[1]);

		m_team1.m_hiding = true;

		@m_hudProphunt = HUDProphunt(m_guiBuilder);
		@m_hudBlinded = Blinded(m_guiBuilder);

		@m_hud.m_weaponSwitcher = PhWeaponSwitch(m_guiBuilder, m_hud);
	}

	void RespawnPlayer(PlayerRecord@ record)
	{
		if (!Network::IsServer()) {
			return;
		}

		record.actor.m_unit.Destroy();
		@record.actor = null;
		record.deadTime = g_scene.GetTime();

		AttemptRespawn(record.peer);
	}

	void SetState(PhGameState state)
	{
		if (!Network::IsServer()) {
			return;
		}

		if (m_state == PhGameState::EndOfRound && state == PhGameState::Hiding) {
			print("[Prophunt] Starting new round, switching teams.");
			m_team1.m_hiding = !m_team1.m_hiding;
			m_team2.m_hiding = !m_team2.m_hiding;

			for (uint i = 0; i < m_team1.m_players.length(); i++) {
				RespawnPlayer(m_team1.m_players[i]);
			}
			for (uint i = 0; i < m_team2.m_players.length(); i++) {
				RespawnPlayer(m_team2.m_players[i]);
			}
		} else if (m_state == PhGameState::Hiding && state == PhGameState::Seeking) {
			print("[Prophunt] Seekers are released!");
		} else if (state == PhGameState::EndOfRound) {
			print("[Prophunt] End of game!");
		}
		m_state = state;
		m_tmStartState = CurrPlaytimeLevel();

		//TODO: Send network message to clients that state has changed
	}

	void Start(uint8 peer, SValue@ save, StartMode sMode) override
	{
		TeamVersusGameMode::Start(peer, save, sMode);

		SetState(PhGameState::Hiding);
	}

	TeamVersusScore@ CreateTeamScore(uint team) override
	{
		return PhTeamScore(team);
	}

	void SpawnPlayer(int i, vec2 pos = vec2(), int unitId = 0, uint team = 0) override
	{
		TeamVersusGameMode::SpawnPlayer(i, pos, unitId, team);

		PhPlayer@ player = cast<PhPlayer>(g_players[i].actor);
		PhTeamScore@ score = cast<PhTeamScore>(FindTeamScore(team));

		if (player !is null) {
			@player.m_phTeam = score;
		}

		if (score.m_hiding) {
			g_players[i].ResetWeaponsAndAmmo();
			GiveWeapons(g_players[i], Weapons::Unarmed);

			if (player !is null) {
				player.SwitchBestWeapon(true);
			}
		}
	}

	void HandleStates()
	{
		if (!Network::IsServer()) {
			return;
		}

		uint tmNow = CurrPlaytimeLevel() - m_tmStartState;
		if (m_state == PhGameState::Hiding) {
			if (tmNow > m_tmLimitHiding) {
				SetState(PhGameState::Seeking);
			}
		} else if (m_state == PhGameState::Seeking) {
			if (tmNow > m_tmLimitSeeking) {
				SetState(PhGameState::EndOfRound);
			}
		} else if (m_state == PhGameState::EndOfRound) {
			if (tmNow > m_tmLimitEndOfRound) {
				SetState(PhGameState::Hiding);
			}
		}
	}

	void UpdateFrame(int ms, GameInput& gameInput, MenuInput& menuInput) override
	{
		TeamVersusGameMode::UpdateFrame(ms, gameInput, menuInput);

		HandleStates();
	}

	void UpdateWidgets(int ms, GameInput& gameInput, MenuInput& menuInput) override
	{
		TeamVersusGameMode::UpdateWidgets(ms, gameInput, menuInput);

		m_hudProphunt.Update(ms);

		VersusPlayerRecord@ player = cast<VersusPlayerRecord>(GetLocalPlayerRecord());

		PhTeamScore@ team = cast<PhTeamScore>(GetPlayerTeam(player));
		if (team is null) {
			return;
		}

		if (m_state == PhGameState::Hiding) {
			if (!team.m_hiding) {
				m_hudBlinded.Update(ms);
			}
		}
	}

	void RenderFrame(int idt, SpriteBatch& sb) override
	{
		PhPlayer@ player = cast<PhPlayer>(GetLocalPlayer());

		if (player !is null) {
			m_hudProphunt.Draw(sb, idt);

			PhTeamScore@ team = player.m_phTeam;

			if (team !is null) {
				if (m_state == PhGameState::Hiding) {
					if (!team.m_hiding) {
						m_hudBlinded.Draw(sb, idt);
					}
				}
			}
		}

		if (m_switchTeam.m_visible) {
			sb.FillRectangle(vec4(0, 0, 2048, 2048), vec4(0, 0, 0, 1));
		}

		TeamVersusGameMode::RenderFrame(idt, sb);
	}
}
