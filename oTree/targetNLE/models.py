import random

from django.utils.translation import gettext as _
from otree.api import (
    models,
    BaseConstants,
    BaseSubsession,
    BaseGroup,
    BasePlayer,
    Currency as c,
)

author = 'D. Dubois'

doc = """
Number Line Estimate
"""


class Constants(BaseConstants):
    name_in_url = 'tnle'
    players_per_group = None
    num_rounds = 15
    decision_time = 10

    cibles = dict(zip(range(1, 16),
                      [12.2, 39.87, 68.02, 77.42, 47.95, 16.33, 26.76, 84.58, 94.21, 5.87, 64.9, 45.49, 74.67, 37.6,
                       7.76]))


class Subsession(BaseSubsession):
    def creating_session(self):
        if self.round_number == 1:
            for p in self.get_players():
                p.NLE_paid_decision = random.randint(1, Constants.num_rounds)

        for p in self.get_players():
            p.NLE_nombre_cible = Constants.cibles[self.round_number]


class Group(BaseGroup):
    pass


class Player(BasePlayer):
    NLE_paid_decision = models.IntegerField()
    NLE_nombre_cible = models.FloatField()
    NLE_curseur_position = models.FloatField()

    def compute_payoff(self):
        self.payoff = c(3 - 0.05 * abs(self.NLE_curseur_position - self.NLE_nombre_cible))

        if self.payoff < 0:
            self.payoff = c(0)

        if self.round_number == Constants.num_rounds:
            paid_decision = self.in_round(1).NLE_paid_decision
            paid_round = self.in_round(paid_decision)

            txt_final = _("C'est l'exercice {} qui a été sélectionné pour déterminer votre gain à cette tâche.").format(
                paid_decision)
            txt_final += " " + _("A cet exercice la valeur cible était {}. Vous avez positionné le curseur sur {}.").format(
                paid_round.NLE_nombre_cible, paid_round.NLE_curseur_position)
            txt_final += " " + _("Votre gain pour cette tâche est de {:.2f} euros.").format(paid_round.payoff)

            self.participant.vars["targetNLE_txt_final"] = txt_final
            self.participant.vars["targetNLE_payoff"] = paid_round.payoff
