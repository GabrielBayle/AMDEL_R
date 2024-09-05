import random

from otree.api import Currency as c, currency_range
from ._builtin import Page, WaitPage
from .models import Constants
from django.utils.translation import gettext as _


class Instructions(Page):
    def is_displayed(self):
        return self.round_number == 1

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class Decision(Page):
    timeout_seconds = Constants.decision_time
    timer_text = _("Temps Restant : ")
    form_model = "player"
    form_fields = ["NLE_curseur_position"]

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        if self.timeout_happened:
            if random.random() >= 0.1:
                self.player.NLE_curseur_position = self.player.NLE_nombre_cible
            else:
                self.player.NLE_nombre_cible = random.random() * 100
        self.player.compute_payoff()


class Results(Page):
    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class Final(Page):
    def is_displayed(self):
        return self.round_number == Constants.num_rounds

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


page_sequence = [Instructions, Decision, Final]
