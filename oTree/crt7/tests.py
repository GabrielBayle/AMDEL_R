from . import pages
from ._builtin import Bot
from .models import Constants


class PlayerBot(Bot):

    def play_round(self):
        yield (
            pages.Cognitive,
            {"crt_{}".format(i): a for i, a in enumerate(Constants.answers)}
        )
        yield (pages.Summary)
