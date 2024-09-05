from ._builtin import Page


class Answers(Page):
    form_model = "player"
    form_fields = ["nep_{}".format(i) for i in range(1, 16)]

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        self.player.compute_score()


page_sequence = [Answers]

