class PhWeaponSwitch : WeaponSwitch
{
	PhWeaponSwitch(GUIBuilder@ b, HUD@ hud)
	{
		super(b, hud);
	}

	void Update(int dt) override
	{
		PhPlayer@ player = cast<PhPlayer>(GetLocalPlayer());
		if (player is null) {
			return;
		}

		PropHunt@ gm = cast<PropHunt>(g_gameMode);

		if (player.m_phTeam.m_hiding) {
			return;
		} else if (gm.m_state == PhGameState::Hiding) {
			return;
		}

		WeaponSwitch::Update(dt);
	}
}
