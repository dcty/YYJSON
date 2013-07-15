//
//  YYTestViewController.m
//  YYJSON
//
//  Created by Ivan on 13-7-15.
//  Copyright (c) 2013 Ivan. All rights reserved.
//

#import "YYTestViewController.h"
#import "YYUtils.h"
#import "NSData+YYJSON.h"
#import "Shot.h"

@interface YYTestViewController ()
@property(strong, nonatomic) NSData *data;
@property(strong, nonatomic) UIButton *parseButton;
@property(strong, nonatomic) UILabel *resultLabel;
@property(strong, nonatomic) NSMutableArray *array1;
@property(strong, nonatomic) NSMutableArray *array2;
@property(strong, nonatomic) NSMutableArray *array3;
@property(strong, nonatomic) NSMutableArray *array4;
@end

@implementation YYTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.array1 = [[NSMutableArray alloc] init];
        self.array2 = [[NSMutableArray alloc] init];
        self.array3 = [[NSMutableArray alloc] init];
        self.array4 = [[NSMutableArray alloc] init];
    }

    return self;
}


- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor grayColor];
    self.parseButton = [[UIButton alloc] initWithFrame:CGRectMake(130, 10, 60, 80)];
    [_parseButton setTitle:@"parse" forState:UIControlStateNormal];
    [_parseButton setTitleColor:[UIColor redColor] forState:UIControlStateDisabled];
    [_parseButton addTarget:self action:@selector(parse:) forControlEvents:UIControlEventTouchUpInside];
    self.resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 100, 300, 200)];
    _resultLabel.numberOfLines = 0;
    [self.view addSubview:_parseButton];
    [self.view addSubview:_resultLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _parseButton.enabled = NO;
    [self startRequest];
}

- (void)startRequest
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://url.cn/DjjSlB"];
        self.data = [NSData dataWithContentsOfURL:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            _parseButton.enabled = YES;
        });
    });
}

static int times = 100;

- (void)parse:(id)sender
{
    for (int i = 0; i < times; i++)
    {
        [self go];
    }
}

- (void)go
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CGFloat time2 = YYTimeBlock(^{
            [NSData setYYJSONParserType:YYJSONKit];
            [_data toModels:[Shot class] forKey:@"shots"];
        });
        CGFloat time3 = YYTimeBlock(^{
            [NSData setYYJSONParserType:YYJsonLiteParser];
            [_data toModels:[Shot class] forKey:@"shots"];
        });
        CGFloat time4 = YYTimeBlock(^{
            [NSData setYYJSONParserType:YYOKJSONParser];
            [_data toModels:[Shot class] forKey:@"shots"];
        });
        CGFloat time1 = YYTimeBlock(^{
            [NSData setYYJSONParserType:YYNSJSONSerialization];
            [_data toModels:[Shot class] forKey:@"shots"];
        });
        [_array1 addObject:@(time1)];
        [_array2 addObject:@(time2)];
        [_array3 addObject:@(time3)];
        [_array4 addObject:@(time4)];
        [self updateResultLabel];
    });
}


- (void)updateResultLabel
{
    NSMutableString *string = [[NSMutableString alloc] initWithFormat:@"一共%d次，以下时间为平均时间\n", _array1.count];
    [string appendFormat:@"%f:YYNSJSONSerialization\n", [[_array1 valueForKeyPath:@"@avg.floatValue"] floatValue]];
    [string appendFormat:@"%f:YYJSONKit\n", [[_array2 valueForKeyPath:@"@avg.floatValue"] floatValue]];
    [string appendFormat:@"%f:YYJsonLiteParser\n", [[_array3 valueForKeyPath:@"@avg.floatValue"] floatValue]];
    [string appendFormat:@"%f:YYOKJSONParser\n", [[_array4 valueForKeyPath:@"@avg.floatValue"] floatValue]];
    dispatch_async(dispatch_get_main_queue(), ^{
        _resultLabel.text = string;
    });
}

@end
