# -*- coding: utf-8 -*-
"""Төлбөрийн түүх харуулах wizard / Payment history wizard"""

from odoo import models, fields, api


class PaymentHistoryWizard(models.TransientModel):
    """Төлбөрийн түүх харуулах popup цонх"""
    _name = 'payment.history.wizard'
    _description = 'Төлбөрийн түүх Wizard'

    invoice_id = fields.Many2one(
        'account.move',
        string='Нэхэмжлэх',
        readonly=True,
        help='Төлбөрийн түүх харах нэхэмжлэх'
    )
    payment_line_ids = fields.One2many(
        'payment.history.line',
        'wizard_id',
        string='Төлбөрийн түүх',
        compute='_compute_payment_lines',
        help='Нэхэмжлэх дээрх төлөлтүүдийн жагсаалт'
    )

    @api.depends('invoice_id')
    def _compute_payment_lines(self):
        """
        Нэхэмжлэхтэй холбоотой төлөлтүүдийг олж жагсаалт үүсгэх
        """
        for wizard in self:
            lines = []
            if wizard.invoice_id:
                # Odoo-ийн стандарт арга ашиглан хийгдсэн төлөлтүүдийг олох
                payments = wizard.invoice_id._get_reconciled_payments()

                # Төлөлт бүрийг мөр болгон хөрвүүлэх
                for payment in payments:
                    lines.append((0, 0, {
                        'payment_date': payment.date,
                        'amount': payment.amount,
                        'journal_name': payment.journal_id.name,
                        'ref': payment.ref or payment.name or '',
                    }))

            wizard.payment_line_ids = lines


class PaymentHistoryLine(models.TransientModel):
    """Төлбөрийн түүхийн мөр / Payment history line"""
    _name = 'payment.history.line'
    _description = 'Payment History Line'

    wizard_id = fields.Many2one('payment.history.wizard', string='Wizard', required=True)
    payment_date = fields.Date(string='Огноо', help='Төлөлт хийгдсэн огноо')
    amount = fields.Float(string='Дүн', help='Төлсөн дүн')
    journal_name = fields.Char(string='Журнал', help='Журналын нэр')
    ref = fields.Char(string='Тайлбар', help='Төлбөрийн тайлбар эсвэл дугаар')
