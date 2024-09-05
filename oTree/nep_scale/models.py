from django.utils.translation import ugettext as _
from otree.api import (
    models, BaseConstants, BaseSubsession, BaseGroup, BasePlayer
)

author = 'Dimitri DUBOIS'

doc = """
NEP Scale: questions to evaluate the sensity of the participant to question related to the environment
"""


class Constants(BaseConstants):
    name_in_url = 'nep_scale'
    players_per_group = None
    num_rounds = 1


class Subsession(BaseSubsession):
    pass


class Group(BaseGroup):
    pass


def get_field(the_label):
    return models.IntegerField(
        choices=[(1, _("Pas du tout d'accord")), (2, _("Plutôt pas d'accord")), (3, _("Je ne sais pas")),
                 (4, _("Plutôt d'accord")), (5, _("Tout à fait d'accord"))],
        label=the_label
    )


class Player(BasePlayer):
    nep_1 = get_field(_("Nous nous approchons du nombre limite de personnes que la terre peut nourrir."))
    nep_2 = get_field(_("Les êtres humains ont le droit de modifier l’environnement naturel selon leurs besoins."))
    nep_3 = get_field(_("Quand les êtres humains essaient de changer le cours de la nature cela produit souvent des conséquences désastreuses."))
    nep_4 = get_field(_("L’ingéniosité humaine fera en sorte que nous ne rendrons pas la terre invivable."))
    nep_5 = get_field(_("Les êtres humains sont en train de sérieusement malmener l’environnement."))
    nep_6 = get_field(_("La terre posséderait une infinité de ressources naturelles si seulement nous savions comment en tirer mieux parti."))
    nep_7 = get_field(_("Les plantes et les animaux ont autant le droit que les êtres humains d’exister."))
    nep_8 = get_field(_("L’équilibre de la nature est assez fort pour faire face aux effets des nations industrielles modernes."))
    nep_9 = get_field(_("Malgré des aptitudes particulières, les humains sont toujours soumis aux lois de la nature."))
    nep_10 = get_field(_("La prétendue \"crise écologique\" qui guette le genre humain a été largement exagérée."))
    nep_11 = get_field(_("La terre est comme un vaisseau spatial avec un espace et des ressources très limités."))
    nep_12 = get_field(_("Les humains ont été créés pour gouverner le reste de la nature."))
    nep_13 = get_field(_("L’équilibre de la nature est très fragile et facilement perturbé."))
    nep_14 = get_field(_("Les humains vont un jour apprendre suffisamment sur le fonctionnement de la nature pour pouvoir le contrôler."))
    nep_15 = get_field(_("Si les choses continuent au rythme actuel nous allons bientôt vivre une catastrophe écologique majeure."))

    nep_score = models.IntegerField()

    def compute_score(self):
        def recoded_item(item_value):
            if item_value == 1:
                return 5
            elif item_value == 2:
                return 4
            elif item_value == 4:
                return 2
            elif item_value == 5:
                return 1
            else:  # 3 reste inchangé
                return item_value

        the_answers = []
        for i in range(1, 16):
            the_attr = getattr(self, "nep_{}".format(i))
            if i % 2 == 0:
                the_answers.append(recoded_item(the_attr))
            else:
                the_answers.append(the_attr)

        self.nep_score = sum(the_answers)
