{
    'name': 'Invoice Payment Details',
    'version': '1.0',
    'category': 'Accounting',
    'summary': 'Show payment history details on invoices',
    'description': """
        This module adds:
        - Amount paid column on invoice list
        - Payment history details button
        - Payment history popup wizard
        - PDF report with payment information
    """,
    'depends': ['account'],
    'data': [
        'security/security.xml',
        'security/ir.model.access.csv',
        'wizard/payment_history_wizard_views.xml',
        'views/account_move_views.xml',
        'views/account_move_form_restrict.xml',
        'reports/invoice_report_template.xml',
    ],
    'installable': True,
    'application': False,
    'license': 'LGPL-3',
}
