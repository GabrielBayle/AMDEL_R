from otree.api import Currency as c, currency_range, Submission
from . import pages
from ._builtin import Bot
from .models import Constants


class PlayerBot(Bot):
    def play_round(self):
        if self.round_number == 1:
            yield pages.Instructions
        yield Submission(pages.Decision, timeout_happened=True)
        if self.round_number == Constants.num_rounds:
            yield pages.Final
