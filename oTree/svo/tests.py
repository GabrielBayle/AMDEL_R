import random

from otree.api import Submission

from . import pages
from ._builtin import Bot
from .models import Constants


class PlayerBot(Bot):

    def play_round(self):

        yield Submission(
            pages.SVODecision, dict(
                svo_choice_1=random.randint(0, len(Constants.matrices[1][0])-1),
                svo_choice_2=random.randint(0, len(Constants.matrices[2][0]) - 1),
                svo_choice_3=random.randint(0, len(Constants.matrices[3][0]) - 1),
                svo_choice_4=random.randint(0, len(Constants.matrices[4][0]) - 1),
                svo_choice_5=random.randint(0, len(Constants.matrices[5][0]) - 1),
                svo_choice_6=random.randint(0, len(Constants.matrices[6][0]) - 1),
            )
        )

        yield pages.SVOResults

