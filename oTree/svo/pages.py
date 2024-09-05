from ._builtin import Page, WaitPage
from .models import Constants


class SVOAppariemment(WaitPage):
    group_by_arrival_time = True


class SVODecision(Page):
    form_model = "player"
    form_fields = [
        "svo_choice_1", "svo_choice_2", "svo_choice_3",
        "svo_choice_4", "svo_choice_5", "svo_choice_6"
    ]

    def vars_for_template(self):
        return dict(conversion=10*Constants.conversion)

    def js_vars(self):
        return dict(matrices=Constants.matrices, fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        self.player.compute_score()


class SVOBeforeResults(WaitPage):
    after_all_players_arrive = "compute_payoffs"


class SVOResults(Page):
    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


page_sequence = [SVOAppariemment, SVODecision, SVOBeforeResults, SVOResults]
