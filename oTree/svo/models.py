import json
import random

import numpy as np
from django.utils.translation import gettext as _
from otree.api import (
    models, BaseConstants, BaseSubsession, BaseGroup, BasePlayer
)

author = 'D. DUBOIS'

doc = """
SVO - 6 matrices
"""


class Constants(BaseConstants):
    name_in_url = 'svo'
    players_per_group = 2
    num_rounds = 1

    with open("svo/matrices.json", "r") as file:
        matrices = json.load(file)

    conversion = 0.1


class Subsession(BaseSubsession):
    pass


class Group(BaseGroup):
    selected_choice = models.IntegerField()
    selected_player = models.IntegerField()
    selected_player_decision = models.IntegerField()
    selected_player_payoff = models.IntegerField()
    non_selected_player_payoff = models.IntegerField()

    def compute_payoffs(self):
        self.selected_choice = random.randint(1, 6)
        self.selected_player = random.randint(1, 2)
        self.selected_player_decision = getattr(self.get_player_by_id(self.selected_player),
                                                f"svo_choice_{self.selected_choice}")
        self.selected_player_payoff = Constants.matrices[str(self.selected_choice)]["self"][self.selected_player_decision]
        self.non_selected_player_payoff = Constants.matrices[str(self.selected_choice)]["other"][
            self.selected_player_decision]

        for p in self.get_players():
            p.compute_payoff()


class Player(BasePlayer):
    svo_choice_1 = models.IntegerField(blank=True)
    svo_choice_2 = models.IntegerField(blank=True)
    svo_choice_3 = models.IntegerField(blank=True)
    svo_choice_4 = models.IntegerField(blank=True)
    svo_choice_5 = models.IntegerField(blank=True)
    svo_choice_6 = models.IntegerField(blank=True)
    svo_mean_self = models.FloatField()
    svo_mean_other = models.FloatField()
    svo_score = models.FloatField()

    def compute_score(self):
        values_self, values_other = [], []
        for i, matrice in Constants.matrices.items():
            values_self.append(matrice["self"][getattr(self, f"svo_choice_{i}")])
            values_other.append(matrice["other"][getattr(self, f"svo_choice_{i}")])
        self.svo_mean_self = np.round(np.mean(values_self), 3)
        self.svo_mean_other = np.round(np.mean(values_other), 3)
        self.svo_score = np.round(np.degrees(np.arctan((self.svo_mean_other - 50) / (self.svo_mean_self - 50))), 3)

    def compute_payoff(self):
        txt_final = _("C'est le tableau {} qui a été aléatoirement sélectionné.").format(self.group.selected_choice)
        txt_final += " "
        if self.group.selected_player == self.id_in_group:
            txt_final += _("C'est votre décision qui s'est appliquée dans la paire. Vous avez choisi la répartition "
                          "{} ECUs pour vous et {} ECUs pour l'autre.").format(self.group.selected_player_payoff,
                                                                     self.group.non_selected_player_payoff)
            txt_final += " "
            txt_final += _("Vous gagnez donc {:.2f} euros et l'autre personne de votre paire gagne {:.2f} euros.").format(
                self.group.selected_player_payoff * Constants.conversion,
                self.group.non_selected_player_payoff * Constants.conversion)
            self.payoff = self.group.selected_player_payoff * Constants.conversion

        else:
            txt_final += _("C'est la décision de l'autre personne qui s'est appliquée dans le groupe. Elle a choisi "
                           "la répartition {} ECUs pour elle et {} ECUs pour vous.").format(
                self.group.selected_player_payoff, self.group.non_selected_player_payoff)
            txt_final += " "
            txt_final += _("Vous gagnez donc {:.2f} euros et l'autre personne de votre paire gagne {:.2f} euros.").format(
                self.group.non_selected_player_payoff * Constants.conversion,
                self.group.selected_player_payoff * Constants.conversion)
            self.payoff = self.group.non_selected_player_payoff * Constants.conversion

        self.participant.vars["svo_txt_final"] = txt_final
        self.participant.vars["svo_payoff"] = self.payoff
