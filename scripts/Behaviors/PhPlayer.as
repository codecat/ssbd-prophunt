class PhPlayer : Player
{
	PhTeamScore@ m_phTeam;

	UnitScene@ m_phProp;

	PhPlayer(UnitPtr unit, SValue& params)
	{
		super(unit, params);
	}

	int RefreshScene() override
	{
		if (m_phTeam.m_hiding && m_phProp !is null) {
			m_playerBobbing = false;

			m_unitScene.Clear();
			m_unitScene.AddScene(m_phProp, 0, vec2(), 0, 0);
			m_unit.SetUnitScene(m_unitScene, false);
			return 0;
		} else if (!m_phTeam.m_hiding) {
			@m_phProp = null;
		}

		m_playerBobbing = true;
		return Player::RefreshScene();
	}

	void UpdateHiding(int dt)
	{
		GameInput@ input = GetInput();

		input.Attack.Pressed = false;
		input.Attack.Down = false;
		input.Attack.Released = false;

		if (input.Use.Pressed) {
			//TODO: This currently only works with mouse!
			vec3 mousePos = ToWorldspace(input.MousePos);
			array<UnitPtr>@ arrUnits = g_scene.QueryCircle(xy(mousePos), 4, ~0, RaycastType::Any, true);

			for (uint i = 0; i < arrUnits.length(); i++) {
				UnitPtr unit = arrUnits[i];

				if (dist(unit.GetPosition(), m_unit.GetPosition()) > 30) {
					continue;
				}

				if (cast<Actor>(unit.GetScriptBehavior()) !is null) {
					continue;
				}

				@m_phProp = unit.GetCurrentUnitScene();
			}
		}

		Player::Update(dt);
	}

	void UpdateSeeking(int dt)
	{
		PropHunt@ gm = cast<PropHunt>(g_gameMode);
		if (gm.m_state == PhGameState::Hiding) {
			return;
		}

		Player::Update(dt);
	}

	void Update(int dt) override
	{
		if (m_phTeam.m_hiding) {
			UpdateHiding(dt);
		} else {
			UpdateSeeking(dt);
		}
	}
}
