from otree.api import (
    BaseConstants, BaseSubsession, BaseGroup, BasePlayer
)


author = 'D. Dubois'

doc = """
Welcome screen
"""


class Constants(BaseConstants):
    name_in_url = 'welcome'
    players_per_group = None
    num_rounds = 1


class Subsession(BaseSubsession):
    pass


class Group(BaseGroup):
    pass


class Player(BasePlayer):
    pass
