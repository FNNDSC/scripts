#!/usr/bin/env python
# 
# NAME
#
#        CMail_drive.py
#
# DESCRIPTION
#
#         A simple 'driver' for a C_Mail class instance
#
# HISTORY
#
# 11 January 2007
# o Initial development implementation.
#

import C_mail

CMail = C_mail.C_mail()

str_magnet      = 'MR_WALTHAM260PR'
str_report      = 'QAplots-%s.txt' % str_magnet
str_plots       = 'QAplots-%s.png' % str_magnet

lstr_to                = ['rudolph@nmr.mgh.harvard.edu']
str_subject        = "QA Report - %s" % str_magnet
str_body        = open(str_report, 'r').read()
str_from        = "sdc@holocene.nmr.mgh.harvard.edu"
lstr_attach     = [str_plots]

CMail.mstr_SMTPserver = "smtp.nmr.mgh.harvard.edu"
#CMail.mstr_SMTPserver = "smtp.comcast.net"
CMail.send(     to=lstr_to, subject=str_subject, body=str_body, 
                sender=str_from, attach=lstr_attach)

