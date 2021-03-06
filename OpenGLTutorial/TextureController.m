//
//  TextureController.m
//  OpenGLTutorial4
//
//  Created by Eric Lanz on 2/12/13.
//  Copyright (c) 2013 200Monkeys. All rights reserved.
//

#import "TextureController.h"
#import "AFNetworking.h"

#define kMonkeySize 128

@implementation ESTextureInfo @end

@implementation TextureController

- (id) initWithShareGroup:(EAGLSharegroup*)sharegroup
{
    if ((self = [super init]))
    {
        _loaderContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:sharegroup];
    }
    return self;
}

- (ESTextureInfo*) loadMonkeyTextureWithSuccess:(textureLoadSuccessBlock)success failure:(textureLoadFailureBlock)failure
{
    ESTextureInfo * info = [[ESTextureInfo alloc] init];
    
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.200monkeys.com/200Monkeys/wp-content/uploads/2013/02/monkey.png"]];
    
    AFImageRequestOperation * operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        GLubyte *imageData = (GLubyte *) calloc(1, kMonkeySize * kMonkeySize * 4);
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
        CGContextRef c = CGBitmapContextCreate(imageData, kMonkeySize, kMonkeySize, 8,
                                               kMonkeySize * 4, genericRGBColorspace,
                                               kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextScaleCTM(c, 1.0, -1.0);
        CGContextTranslateCTM(c, 0, -kMonkeySize);
        CGContextDrawImage(c, CGRectMake(0, 0, kMonkeySize, kMonkeySize), image.CGImage);
        CGContextRelease(c);
        CGColorSpaceRelease(genericRGBColorspace);
        info.height = kMonkeySize;
        info.width = kMonkeySize;
        info.textureName = [self pushTextureToGL:imageData width:kMonkeySize height:kMonkeySize inEAGL:_loaderContext];
        free(imageData);
        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"image download error: %@", error);
        if (failure) failure();
    }];
    [[NSOperationQueue mainQueue] addOperation:operation];
    
    return info;
}

- (GLuint) pushTextureToGL:(GLubyte*)imageData width:(float)width height:(float)height inEAGL:(EAGLContext*)eagl
{
    [EAGLContext setCurrentContext:eagl];
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);
    glFlush();
    [EAGLContext setCurrentContext:nil];
    return texName;
}

@end
