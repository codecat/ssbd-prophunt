class Blinded : IWidgetHoster
{
	TextWidget@ m_wTime;

	Blinded(GUIBuilder@ b)
	{
		LoadWidget(b, "gui/blinded.gui");

		@m_wTime = cast<TextWidget>(m_widget.GetWidgetById("time"));
	}

	void Update(int dt) override
	{
		IWidgetHoster::Update(dt);

		PropHunt@ gm = cast<PropHunt>(g_gameMode);

		uint tmNow = CurrPlaytimeLevel() - gm.m_tmStartState;

		uint tmLeft = max(0, gm.m_tmLimitHiding - tmNow);
		m_wTime.SetText("You will be unblinded in: " + formatTime(ceil(tmLeft / 1000.0f), false));

		DoLayout();
	}
}
