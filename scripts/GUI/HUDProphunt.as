class HUDProphunt : IWidgetHoster
{
	TextWidget@ m_wTime;

	HUDProphunt(GUIBuilder@ p)
	{
		LoadWidget(p, "gui/prophunt.gui");

		@m_wTime = cast<TextWidget>(m_widget.GetWidgetById("limit-time"));
	}

	void Update(int dt) override
	{
		IWidgetHoster::Update(dt);

		PropHunt@ gm = cast<PropHunt>(g_gameMode);

		uint tmNow = CurrPlaytimeLevel() - gm.m_tmStartState;

		if (gm.m_state == PhGameState::Hiding) {
			uint tmLeft = max(0, gm.m_tmLimitHiding - tmNow);
			m_wTime.SetText("Hiding: " + formatTime(ceil(tmLeft / 1000.0f), false));
		} else if (gm.m_state == PhGameState::Seeking) {
			uint tmLeft = max(0, gm.m_tmLimitSeeking - tmNow);
			m_wTime.SetText("Seeking: " + formatTime(ceil(tmLeft / 1000.0f), false));
		} else if (gm.m_state == PhGameState::EndOfRound) {
			uint tmLeft = max(0, gm.m_tmLimitEndOfRound - tmNow);
			m_wTime.SetText("Next round in: " + formatTime(ceil(tmLeft / 1000.0f), false));
		}

		DoLayout();
	}
}
