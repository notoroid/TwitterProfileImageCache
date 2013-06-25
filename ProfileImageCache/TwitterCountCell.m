//
//  TwitterCountCell.m
//  TwitterProfileImageCache
//
//  Created by 能登 要 on 13/06/25.
//
//

#import "TwitterCountCell.h"

@implementation TwitterCountCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) prepareForReuse
{
    self.tag = 0;
}

@end
