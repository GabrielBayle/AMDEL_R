from django.utils.translation import ugettext as _
from otree.api import (
    models, BaseConstants, BaseSubsession, BaseGroup, BasePlayer,
    Currency as c
)

author = 'D. Dubois'

doc = """
Cognitive reflexion test - 7 questions
"""


class Constants(BaseConstants):
    name_in_url = 'crt7'
    players_per_group = None
    num_rounds = 1

    answers = dict(zip(range(1, 8), [2, 0.25, 5, 4, 29, 20, 0]))

    gain_par_reponse = 0.5

    temps_max = 20  # en  minutes


class Subsession(BaseSubsession):
    pass


class Group(BaseGroup):
    pass


class Player(BasePlayer):
    crt_1 = models.IntegerField(
        min=0, max=2000,
        label=_("S'il faut 2 minutes à 2 infirmières pour mesurer la pression sanguine de 2 patients, combien de temps "
                "faudrait-il à 200 infirmières pour mesurer la pression sanguine de 200 patients ? (en minutes)"))
    crt_2 = models.FloatField(
        min=0, max=10,
        label=_(
            "Une soupe et une salade coûtent 5.50 euros au total. La soupe coûte 5 euros de plus que la salade. "
            "Combien coûte la salade ? (en euros)."))
    crt_3 = models.IntegerField(
        min=0, max=10,
        label=_(
            "Sally fait du thé. Chaque minute, la concentration du thé double. S'il faut 6 minutes au thé pour être "
            "prêt, combien de temps faudrait-il pour que le thé atteigne la moitié de la concentration finale ? "
            "(en minutes)"))
    crt_4 = models.IntegerField(
        min=0, max=18,
        label=_("Si Jean boit un bidon d'eau en 6 jours et Marie boit un bidon d'eau en 12 jours, combien "
                "de temps leur faut-il pour boire un bidon d'eau ensemble ? (en jours)")
    )
    crt_5 = models.IntegerField(
        min=0, max=40,
        label=_("Jerry a eu à la fois la 15ème meilleure note et la 15ème moins bonne note de sa classe. Combien "
                "y a-t-il d'élèves dans sa classe ?"))
    crt_6 = models.IntegerField(
        min=0, max=170,
        label=_("Un homme achète un mouton à 60 euros, le revend à 70 euros, l'achète de nouveau à 80 euros pour "
                "finalement le revendre à 90 euros. Quel est son bénéfice total ? (en euros)"))
    crt_7 = models.IntegerField(
        label=_("Simon a investi 8 000 euros dans un actif au mois de janvier. Six mois après qu'il ait investi, le 17 "
                "juillet, la valeur de cet actif a chuté de 50%. Heureusement pour Simon, entre le 17 juillet et "
                "le 17 octobre, la valeur de l'actif a augmenté de 75%. En date du 17 octobre, Simon :"),
        choices=[
            (0, _("a perdu de l'argent")),
            (1, _("n'a ni gagné ni perdu d'argent")),
            (2, _("a gagné de l'argent"))
        ])

    crt_score = models.IntegerField()

    def compute_score(self):
        score = 0
        for i, a in Constants.answers.items():
            if getattr(self, "crt_{}".format(i)) == a:
                score += 1
        self.crt_score = score
        self.payoff = c(self.crt_score * Constants.gain_par_reponse)

        self.participant.vars["crt_txt_final"] = _(
            "Vous avez trouvé {} bonnes réponses, votre gain est donc de {:.2f} euros.").format(self.crt_score,
                                                                                                self.payoff)
        self.participant.vars["crt_payoff"] = self.payoff
