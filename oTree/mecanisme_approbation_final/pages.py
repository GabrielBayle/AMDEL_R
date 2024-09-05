from ._builtin import Page


class Final(Page):
    form_model = "player"
    form_fields = ["comments"]

    def vars_for_template(self):
        return {
            "txt_final": self.participant.vars.get("txt_final", "")
        }

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class Final_after_comments(Page):
    def vars_for_template(self):
        return {
            "txt_final": self.participant.vars.get("txt_final", "")
        }

    def js_vars(self):
        return dict(fill_auto=False)


page_sequence = [Final, Final_after_comments]
