#!/usr/bin/env python

import os, sys
import argparse
import logging, logging.config

# CLASS #######################################################################
class __MaxLevelFilter(logging.Filter):
    def __init__(self, max_level, *args, **kwargs):
        self.max_level = getattr(logging, max_level)        \
                         if isinstance(max_level, str) else \
                            max_level
        logging.Filter.__init__(self, *args, **kwargs)

    def filter(self, record):
        return record.levelno <= self.max_level


# FUNCTIONS ###################################################################
def __parse_input_arguments():
    parser = argparse.ArgumentParser(
        description = 'Install every conf files automatically'
    )

    parser.add_argument(
        '-lglvl', '--log-level',
        choices = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
        default = 'INFO',
        help = 'Logging level',
    )
    return parser.parse_args()


def __configure_logger(log_level):
    return {
        'version': 1,
        'disable_existing_loggers': True,
        'formatters': {
            'default': {
                'format': "[%(asctime)s][%(levelname)-8s]: %(message)s"
            },
            'simple': {
                'format': "[%(asctime)s]: %(message)s"
            },
            'detailed': {
                'format': "[%(asctime)s][%(levelname)-8s][%(name)s]: %(message)s"
            },
        },
        'filters': {
            'warning_maxlevel': {
                '()': __MaxLevelFilter,
                'max_level': 'WARNING',
            },
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'default',
                'level': 'NOTSET',
                'filters': ['warning_maxlevel'],
                'stream': 'ext://sys.stdout',
            },

            'console_stderr': {
                'class': 'logging.StreamHandler',
                'formatter': 'default',
                'level': 'ERROR',
                'stream': 'ext://sys.stderr',
            },
        },
        'loggers': {
            # TODO
        },
        'root' : {
            'level': log_level,
            'handlers': ['console', 'console_stderr'],
        }
    }



def main():
    args = __parse_input_arguments()
    logging.config.dictConfig(
        __configure_logger(log_level = args.log_level)
    )
    log = logging.getLogger(__name__)

    log.debug('A')
    log.info('A')
    log.warning('A')
    log.error('A')
    log.critical('A')


if __name__ == '__main__':
    main()
