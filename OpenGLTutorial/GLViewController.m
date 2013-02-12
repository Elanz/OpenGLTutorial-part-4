//
//  GLViewController.m
//  OpenGLTutorial
//
//  Created by Eric Lanz on 12/28/12.
//  Copyright (c) 2012 200Monkeys. All rights reserved.
//

#import "GLViewController.h"
#import "ShaderController.h"
#import "TextureController.h"
#import "Vertex.h"
#import "ESDrawable.h"

static Vertex QuadVertices[] = {
    {{1, -1, 1}, {1, 0}},
    {{1, 1, 1}, {1, 1}},
    {{-1, 1, 1}, {0, 1}},
    {{-1, -1, 1}, {0, 0}}
};

const GLushort QuadIndices[] = {
    0, 1, 2,
    2, 3, 0
};

#define state_none 0
#define state_lowerleft 2
#define state_lowerright 3
#define state_upperright 4
#define state_upperleft 5

@interface GLViewController ()

@end

@implementation GLViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context)
        NSLog(@"Failed to create ES context");
    
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    view.drawableMultisample = GLKViewDrawableMultisampleNone;
    self.preferredFramesPerSecond = 30;
    
    _shaders = [[ShaderController alloc] init];
    [_shaders loadShaders];
    _textures = [[TextureController alloc] initWithShareGroup:self.context.sharegroup];
    
    glGenBuffers(1, &_quadIndexBuffer);
    glGenBuffers(1, &_quadVertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_TEX01);
    
    glLineWidth(10.0);
    
    _drawables = [NSMutableArray array];

    GLKVector4 color = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    ESDrawable * drawable = [[ESDrawable alloc] initWithShader:_shaders.tileShader
                                                         color:color
                                                      position:GLKVector3Make(0.0, 0.0, 0.0)];
    drawable.texture = [_textures loadMonkeyTextureWithSuccess:^{
        NSLog(@"texture loaded");
    } failure:nil];
    
    [_drawables addObject:drawable];
    
    glBindBuffer(GL_ARRAY_BUFFER, _quadVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(QuadVertices), QuadVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(QuadIndices), QuadIndices, GL_STATIC_DRAW);
    
    _animationState = state_none;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT);
    [_drawables enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(ESDrawable*)obj drawWithView:_viewMatrix];
    }];

#ifdef DEBUG
    static int framecount = 0;
    framecount ++;
    if (framecount > 30)
    {
        float ft = self.timeSinceLastDraw;
        NSString * debugText = [NSString stringWithFormat:@"%2.1f, %0.3f", 1.0/ft, ft];
        [self.debugLabel setText:debugText];
        framecount = 0;
    }
#endif
}

- (void)switchAnimationStateWithDrawable:(ESDrawable*)drawable
{
    // do a spin before each state change unless its the first one:
    if (_animationState != state_none) {
        float newZRotation = drawable.dest_rotation.z;
        newZRotation += 90.0;
        newZRotation = fmodf(newZRotation, 360.0);
        [drawable setDest_rotation:GLKVector3Make(0.0, 0.0, newZRotation)];
    }
    
    switch (_animationState) {
        case state_none:
        case state_lowerright: {
            [drawable setDest_position:GLKVector3Make(-2, -2, 0)];
            _animationState = state_lowerleft;
        } break;
        case state_lowerleft: {
            [drawable setDest_position:GLKVector3Make(-2, 2, 0)];
            _animationState = state_upperleft;
        } break;
        case state_upperleft: {
            [drawable setDest_position:GLKVector3Make(2, 2, 0)];
            _animationState = state_upperright;
        } break;
        case state_upperright: {
            [drawable setDest_position:GLKVector3Make(2, -2, 0)];
            _animationState = state_lowerright;
        } break;
        default:
            break;
    }
}

- (void)update
{
    float aspect = fabsf([UIScreen mainScreen].bounds.size.width / [UIScreen mainScreen].bounds.size.height);
    _viewMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0f), aspect, 1.0, 100.0);
    [_drawables enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ESDrawable * drawable = obj;
        
        if (GLKVector3AllEqualToVector3(drawable.position, drawable.dest_position))
            [self switchAnimationStateWithDrawable:drawable];
        
        [drawable updateWithDeltaTime:self.timeSinceLastUpdate];
    }];
}

@end
