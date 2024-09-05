import json
import random

from django.utils.translation import gettext as _
from otree.api import (
    models,
    widgets,
    BaseConstants,
    BaseSubsession,
    BaseGroup,
    BasePlayer,
    Currency as c,
)

author = 'D. Dubois'

doc = """
Mécanisme approbation
"""


class Constants(BaseConstants):
    name_in_url = 'ma'
    players_per_group = 3  # si ce paramètre est changé cela a des implications sur les textes des pages
    other_players_per_group = players_per_group - 1

    num_rounds = 20  # rounds 1-10 baseline, rounds 11-20 either baseline, majority, unanimity
    round_second_part = 11

    # parameters
    endowment = 10
    gain_activite_B = 15

    # treatments
    baseline = 0
    majority = 1
    unanimity = 2

    # understanding
    with open("mecanisme_approbation/understanding.json", "r") as f:
        understanding = json.load(f)

    conversion = 0.0667


class Subsession(BaseSubsession):
    treatment = models.IntegerField()
    is_test = models.BooleanField()

    def creating_session(self):
        self.treatment = self.session.config.get("treatment", Constants.baseline)
        self.is_test = self.session.config.get("is_test", False)

        if self.round_number == 1:
            self.group_randomly()
            for p in self.get_players():
                p.paid_round = random.randint(1, Constants.num_rounds)
        else:
            self.group_like_round(1)

        for g in self.get_groups():
            dictator = random.choice(g.get_players())
            dictator.dictator = True

    def set_understanding(self):
        """ fonction appelée dans before_next_page de la page Instructions"""
        if self.round_number == 1:
            self.session.vars["understanding"] = Constants.understanding["baseline"]
        else:
            self.session.vars["understanding"] = Constants.understanding["majority"] if \
                self.treatment == Constants.majority else Constants.understanding["unanimity"]

    def set_groups_extractions(self):
        for g in self.get_groups():
            g.set_group_extraction()

    def set_groups_approbation(self):
        for g in self.get_groups():
            g.set_group_approbation()

    def compute_payoffs(self):
        for p in self.get_players():
            p.compute_payoffs()
        for p in self.get_players():
            p.set_text_result()
        if self.round_number == Constants.num_rounds:
            for p in self.get_players():
                p.compute_final_payoff()

    def vars_for_admin_report(self):
        players_infos = list()
        for p in self.get_players():
            players_infos.append(dict(
                participant=p.participant.code,
                participant_label=p.participant.label,
                group_number=p.group.id_in_subsession,
                paid_round=p.in_round(1).paid_round,
                payoff=float(p.payoff),
                part_payoff=float(p.in_round(p.in_round(1).paid_round).payoff)
            ))
        return dict(players_infos=players_infos)


class Group(BaseGroup):
    extraction_group = models.IntegerField()
    approbation_yes = models.IntegerField()
    approbation_no = models.IntegerField()
    approbation_group = models.BooleanField()
    extraction_dictator = models.IntegerField()
    extraction_group_applied = models.IntegerField()

    def set_group_extraction(self):
        self.extraction_group = sum([p.extraction for p in self.get_players()])
        if self.subsession.treatment != Constants.baseline and self.round_number >= Constants.round_second_part:
            for p in self.get_players():
                p.compute_payoffs_before_approbation()

    def set_group_approbation(self):
        self.approbation_yes = sum([p.approbation for p in self.get_players()])
        self.approbation_no = Constants.players_per_group - self.approbation_yes

        if self.subsession.treatment == Constants.unanimity:
            self.approbation_group = self.approbation_yes == Constants.players_per_group

        elif self.subsession.treatment == Constants.majority:
            self.approbation_group = self.approbation_yes > self.approbation_no

    def extraction_dictator_min(self):
        return min([p.extraction for p in self.get_players()])

    def extraction_dictator_max(self):
        return max([p.extraction for p in self.get_players()])

    def set_extraction_applied(self):
        self.extraction_group_applied = self.extraction_dictator * Constants.players_per_group
        for p in self.get_players():
            p.extraction_applied = self.extraction_dictator

    def get_dictator(self):
        return [p for p in self.get_players() if p.dictator][0]


class Player(BasePlayer):
    understanding_0 = models.StringField()
    understanding_1 = models.StringField()
    understanding_2 = models.StringField()
    understanding_3 = models.StringField()
    understanding_4 = models.StringField()
    understanding_faults = models.IntegerField()

    paid_round = models.IntegerField()
    dictator = models.BooleanField(initial=False)
    extraction = models.IntegerField(min=0, max=Constants.endowment)
    approbation = models.BooleanField(widget=widgets.RadioSelectHorizontal)
    extraction_applied = models.IntegerField()

    def compute_understanding_faults(self):
        nb_faults = 0
        for i, q in enumerate(self.session.vars["understanding"]):
            if getattr(self, f"understanding_{i}") != q["solution"]:
                nb_faults += 1
        self.understanding_faults = nb_faults

    def compute_payoffs_before_approbation(self):
        indiv = self.extraction
        group = self.group.extraction_group
        try:
            self.payoff = c(int((indiv / group) * (3 * 23 * group - 9 * 0.25 * pow(group, 2)) + 5 * (3 * 10 - 3 * indiv)))
        except ZeroDivisionError:
            self.payoff = c(int(5 * (3 * 10 - 3 * indiv)))

    def compute_payoffs(self):
        if self.round_number < Constants.round_second_part or self.subsession.treatment == Constants.baseline:
            indiv = self.extraction
            group = self.group.extraction_group
        else:
            if self.group.approbation_group:
                indiv = self.extraction
                group = self.group.extraction_group
            else:
                indiv = self.extraction_applied
                group = self.group.extraction_group_applied

        try:
            self.payoff = c(int((indiv / group) * (3 * 23 * group - 9 * 0.25 * pow(group, 2)) + 5 * (3 * 10 - 3 * indiv)))
        except ZeroDivisionError:
            self.payoff = c(int(5 * (3 * 10 - 3 * indiv)))

    def set_text_result(self):
        # Text for result page
        if self.round_number < Constants.round_second_part or \
                (self.round_number >= Constants.round_second_part and self.subsession.treatment == Constants.baseline):
            txt_round = _("Vous avez investi {} jetons dans l'activité A, et les autres membres de votre groupe ont "
                          "investi {} et {} jetons. Au total votre groupe a donc investi {} jetons. Votre gain "
                          "pour la période est de {:.0f} ECUs. Les gains des autres membres de votre groupe sont "
                          "respectivement égaux à {:.0f} ECUs et {:.0f} ECUs.").format(
                self.extraction, self.get_others_in_group()[0].extraction, self.get_others_in_group()[1].extraction,
                self.group.extraction_group, float(self.payoff), float(self.get_others_in_group()[0].payoff),
                float(self.get_others_in_group()[1].payoff))

        else:
            txt_round = _(
                "Vous avez initialement proposé d'investir {} jetons dans l'activité A, et les autres membres de "
                "votre groupe ont proposé d'investir {} et {} jetons.").format(
                self.extraction, self.get_others_in_group()[0].extraction, self.get_others_in_group()[1].extraction)

            txt_round += " "

            if self.group.approbation_yes == 0:
                txt_round += _("Aucun membre du groupe n'a approuvé ces investissements.")
            elif self.group.approbation_yes == 1:
                txt_round += _("Un membre du groupe a approuvé ces investissements, et {} les ont désapprouvés.").format(
                    self.group.approbation_no)
            elif self.group.approbation_yes > 1 and self.group.approbation_no == 1:
                txt_round += _(
                    "{} membres du groupe ont approuvé ces investissements, et un les a désapprouvés.").format(
                    self.group.approbation_yes)
            elif self.group.approbation_yes > 1 and self.group.approbation_no > 1:
                txt_round += _(
                    "{} membres du groupe ont approuvé ces investissements, et {} les ont désapprouvés.").format(
                    self.group.approbation_yes, self.group.approbation_no)
            else:
                txt_round += _("Tous les membres du groupe ont approuvé ces investissements.")

            txt_round += " "
            if self.group.approbation_group:
                txt_round += _("Au total votre groupe a donc investi {} jetons. Votre gain pour la période "
                               "est de {:.0f} ECUs. Les gains des autres membres de votre groupe sont "
                               "respectivement égaux à {:.0f} ECUs et {:.0f} ECUs.").format(
                    self.group.extraction_group, float(self.payoff), float(self.get_others_in_group()[0].payoff),
                    float(self.get_others_in_group()[1].payoff))
            else:
                txt_round += _(
                    "Un membre du groupe a été choisi aléatoirement pour décider de l'investissement de chacun. "
                    "Il a choisi un investissement de {} jetons. Au total votre groupe a donc investi {} jetons. "
                    "Votre gain pour la période est de {:.0f} ECUs. Les gains des autres membres de votre groupe sont "
                    "respectivement égaux à {:.0f} ECUs et {:.0f} ECUs.").format(
                    self.extraction_applied, self.group.extraction_group_applied, float(self.payoff),
                    float(self.get_others_in_group()[0].payoff), float(self.get_others_in_group()[1].payoff))

        self.participant.vars["ma_txt_round"] = txt_round

    def compute_final_payoff(self):
        paid_round = self.in_round(1).paid_round
        paid_round_payoff = self.in_round(paid_round).payoff

        self.participant.vars["ma_payoff"] = paid_round_payoff * Constants.conversion
        self.participant.vars["ma_txt_final"] = _(
            "C'est la période {} qui a été tirée au sort pour votre rémunération de cette partie. A cette période "
            "vous avez gagné {:.0f} ECUs, soit {:.2f} euros.").format(paid_round, paid_round_payoff,
                                                                      paid_round_payoff * Constants.conversion)

        self.participant.payoff = self.participant.vars["ma_payoff"]

    def vars_for_template(self):
        part_1_exemple_2 = _("Exemple : Numerotons les joueurs par 1, 2 et 3. Le joueur 1 décide "
                             "d'investir 8 jetons dans l'activité A et donc 2 jetons dans l'activité B. Le joueur 2 "
                             "décide d'investir 6 jetons dans l'activité A et donc 4 jetons dans l'activité B. Le "
                             "joueur 3 décide d'investir 7 jetons dans l'activité A et donc 3 jetons dans l'activité "
                             "B. Pour le joueur 1 : son investissement dans l'activité A est de 8 jetons "
                             "et la somme de l'investissement des joueurs 2 et 3 est de 13 jetons. Pour le joueur 2 : "
                             "son investissement dans l'activité A est de 6 jetons et la somme de l'investissement des "
                             "joueurs 1 et 3 est de 15 jetons. Pour le joueur 3 : son investissement dans l'activité A "
                             "est de 7 jetons et la somme de l'investissement des joueurs 1 et 2 est de 14 jetons. "
                             "Le gain total du joueur 1 pour la période est donc égal à 204 ECUs. Le gain total "
                             "du joueur 2 est égal à 190 ECUS. Le gain total du joueur 3 est égal à 197 ECUs.")
        part_2_majority_exemple_3 = _("Exemple : numérotons les joueurs par 1, 2 et 3. "
                                      "A la période 4, les investissements proposés à l’étape 1 sont les suivants : "
                                      "4 jetons par le joueur 1, 2 jetons par le joueur 2 et 8 jetons par le joueur 3. "
                                      "Un seul joueur désapprouve et les deux autres approuvent. Les propositions "
                                      "d’investissement de l’étape 1 sont exécutées par l’ordinateur.")
        part_2_majority_exemple_4 = _("Autre exemple: à la période 4, les investissements proposés "
                                      "à l’étape 1 sont les suivants : 4 jetons par le joueur 1, 2 jetons par le joueur "
                                      "2 et 8 jetons par le joueur 3. Un seul joueur approuve et les deux autres "
                                      "désapprouvent. Les propositions de l’étape 1 ne sont pas exécutées. Le joueur 1 "
                                      "est désigné pour être le décideur de la période. Il peut choisir n’importe quel "
                                      "montant d’investissement entre 2 jetons et 8 jetons. Le montant qu’il choisira "
                                      "s’appliquera à tous les joueurs de son groupe. S’il choisit par exemple un "
                                      "niveau d’investissement de 5 jetons, chacun devra investir 5 jetons dans "
                                      "l'activité A.")
        part_2_unanimity_exemple_3 = _("Exemple : numérotons les joueurs par 1, 2 et 3. "
                                       "A la période 4, les investissements proposés à l’étape 1 sont les suivants : "
                                       "4 jetons par le joueur 1, 2 jetons par le joueur 2 et 8 jetons par le joueur 3. "
                                       "Le joueur 2 désapprouve. Les propositions de l’étape 1 ne sont pas exécutées. "
                                       "Le joueur 1 est désigné pour être le décideur de la période. Il peut choisir "
                                       "n’importe quel montant d’investissement entre 2 jetons et 8 jetons. Le montant "
                                       "qu’il choisira s’appliquera à tous les joueurs de son groupe. S’il choisit par "
                                       "exemple un niveau d’investissement de 5 jetons, chacun devra investir 5 jetons "
                                       "dans l’activité A.")

        return dict(
            period=self.round_number if self.round_number < Constants.round_second_part else
            self.round_number - Constants.round_second_part + 1,
            current_part=1 if self.round_number < Constants.round_second_part else 2,
            part_1_exemple_1_gain=5 * Constants.gain_activite_B,
            part_1_exemple_2=part_1_exemple_2,
            conversion=f"{15 * Constants.conversion:.2f}",
            part_2_majority_exemple_3=part_2_majority_exemple_3,
            part_2_majority_exemple_4=part_2_majority_exemple_4,
            part_2_unanimity_exemple_3=part_2_unanimity_exemple_3,
        )
