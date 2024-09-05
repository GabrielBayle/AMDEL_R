import random

from otree.api import Submission

from . import pages
from ._builtin import Bot


class PlayerBot(Bot):
    def play_round(self):
        yield Submission(
            pages.Answers,
            dict(("nep_{}".format(i), random.randint(1, 5)) for i in range(1, 16)),
            check_html=False
        )
