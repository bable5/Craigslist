import codecs
import csv

from django.core.management.base import BaseCommand
from optparse import make_option

from posts.models import PersonalAd
from adaptor.model import CsvDbModel
from adaptor.fields import *

class Module(object):
    logger_name = __name__

from django.db.backends import util

class PersonalAdCsvModel(CsvDbModel):
    class Meta:
        dbModel = PersonalAd
        delimiter = ','
        has_header = True
        update = {
            'keys' : ['postID']
        }

class Command(BaseCommand):
    help = 'Loads personal ad data'
    option_list = BaseCommand.option_list + (
        make_option('-f', '--filename',
            action='store',
            dest='filename',
            default='../personalads.csv',
            type='string',
            help='File name to read data from. Default: personalads.csv',
            ),
    )

    def handle(self, *args, **options):

        print('Loading personal ads')
        with open(options['filename']) as fh:
            my_csv_list = PersonalAdCsvModel.import_data(data=fh)
            for p_ad in my_csv_list:
                print("Import: %s, %s" % (p_ad.id2, p_ad.postTitle))

