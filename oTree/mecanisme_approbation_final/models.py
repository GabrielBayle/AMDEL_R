from otree.api import (
    models, BaseConstants, BaseSubsession, BaseGroup, BasePlayer
)
import random
from django.utils.translation import gettext as _


author = 'D. DUBOIS'

doc = """
Ecran final
"""


class Constants(BaseConstants):
    name_in_url = 'mafin'
    players_per_group = None
    num_rounds = 1


class Subsession(BaseSubsession):
    def vars_for_admin_report(self):
        players_infos = list()
        for p in self.get_players():
            players_infos.append(
                dict(
                    participant=p.participant.code,
                    label=p.participant.label,
                    part_1_payoff=float(p.participant.vars.get("ma_payoff", 0)),
                    part_2_svo_payoff=float(p.participant.vars.get("svo_payoff", 0)),
                    part_2_targetNLE_payoff=float(p.participant.vars.get("targetNLE_payoff", 0)),
                    part_2_crt_payoff=float(p.participant.vars.get("crt_payoff", 0)),
                    part_2_selected_task=p.selected_task,
                    payoff=float(p.payoff)
                )
            )
        return dict(players_infos=players_infos)


class Group(BaseGroup):
    pass


class Player(BasePlayer):
    comments = models.LongStringField(blank=True)
    selected_task = models.IntegerField()

    def start(self):
        self.selected_task = random.randint(1, 3)

        self.payoff = self.participant.vars["ma_payoff"]
        if self.selected_task == 1:
            self.payoff += self.participant.vars["svo_payoff"]
        elif self.selected_task == 2:
            self.payoff += self.participant.vars["targetNLE_payoff"]
        else:
            self.payoff += self.participant.vars["crt_payoff"]

        txt_final = _("Dans la partie 2, c'est la tâche {} qui a été aléatoirement sélectionnée pour votre gain de "
                      "cette partie. Votre gain pour l'expérience est donc de {:.2f} euros.").format(
            self.selected_task, float(self.payoff)
        )
        self.participant.vars["txt_final"] = txt_final

        self.participant.payoff = self.payoff