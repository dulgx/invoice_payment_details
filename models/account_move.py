# -*- coding: utf-8 -*-
"""Нэхэмжлэхийн төлбөрийн мэдээлэл """

from odoo import models, fields, api
from odoo.tools import formatLang


class AccountMove(models.Model):
    """Нэхэмжлэх модель - төлбөрийн мэдээлэл нэмэх"""
    _inherit = 'account.move'

    amount_paid = fields.Monetary(
        string='Төлөгдсөн дүн',
        compute='_compute_amount_paid',
        store=True,
        currency_field='currency_id',
        help='Нэхэмжлэх дээр төлөгдсөн нийт дүн'
    )

    @api.depends('payment_state', 'amount_total', 'amount_residual')
    def _compute_amount_paid(self):
        """Төлөгдсөн дүн тооцоолох: amount_total - amount_residual"""
        for move in self:
            if move.move_type in ('out_invoice', 'in_invoice'):
                move.amount_paid = move.amount_total - move.amount_residual
            else:
                move.amount_paid = 0.0

    def action_view_payment_history(self):
        """Төлбөрийн түүх харуулах wizard нээх"""
        self.ensure_one()
        return {
            'name': 'Төлбөрийн түүх',
            'type': 'ir.actions.act_window',
            'res_model': 'payment.history.wizard',
            'view_mode': 'form',
            'target': 'new',
            'context': {
                'default_invoice_id': self.id,
            }
        }

