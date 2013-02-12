//
//  ESDrawable.m
//  OpenGLTutorial2
//
//  Created by Eric Lanz on 1/3/13.
//  Copyright (c) 2013 200Monkeys. All rights reserved.
//

#import "ESDrawable.h"
#import "TextureController.h"

@implementation ESDrawable

- (id) initWithShader:(GLuint)shader color:(GLKVector4)color position:(GLKVector3)position
{
    if ((self = [super init]))
    {
        _shader = shader;
        _color = color;
        self.position = position;
        self.dest_position = position;
        _rotation = GLKVector3Make(0, 0, 0);
        _dest_rotation = GLKVector3Make(0, 0, 0);
        _scale = GLKVector3Make(10, 10, 1);
        _dest_scale = GLKVector3Make(10, 10, 1);
        _dirty = YES;
    }
    return self;
}

- (void) drawWithView:(GLKMatrix4)viewMatrix
{    
    glUseProgram(_shader);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glVertexAttribPointer(ATTRIB_TEX01, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord1));
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX2], 1, 0, GLKMatrix4Multiply(viewMatrix, _model).m);
    glVertexAttrib4fv(ATTRIB_COLOR, _color.v);
    glBindTexture(GL_TEXTURE_2D, _texture.textureName);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
}

- (void) updateWithDeltaTime:(NSTimeInterval)dTime
{
    float speed = 4;
    
    if (GLKVector3Distance(_rotation, _dest_rotation) > 0.1) {
        [self setRotation:GLKVector3Lerp(_rotation, _dest_rotation, dTime*speed)];
    }
    else {
        [self setRotation:_dest_rotation];
    }
    if (GLKVector3Distance(_position, _dest_position) > 0.1) {  // skip setter because these values are already z adjusted
        _position = GLKVector3Lerp(_position, _dest_position, dTime*speed);
    }
    else {
        _position = _dest_position;
    }
    if (GLKVector3Distance(_scale, _dest_scale) > 0.1) {
        [self setScale:GLKVector3Lerp(_scale, _dest_scale, dTime*speed)];
    }
    else {
        [self setScale:_dest_scale];
    }
    
    static float alpha = 1.0;
    static float delta = -0.05;
    alpha += delta;
    if (alpha <= 0)
        delta = 0.05;
    if (alpha >= 1.0)
        delta = -0.05;
    
    [self setColor:GLKVector4Make(1.0, 1.0, 1.0, alpha)];
    
    if (!_dirty) return;
    
    _model = GLKMatrix4Identity;
    _model = GLKMatrix4Scale(_model, _scale.x, _scale.y, _scale.z);
    _model = GLKMatrix4Translate(_model, _position.x, _position.y, _position.z);
    _model = GLKMatrix4RotateX(_model, GLKMathDegreesToRadians(_rotation.x));
    _model = GLKMatrix4RotateY(_model, GLKMathDegreesToRadians(_rotation.y));
    _model = GLKMatrix4RotateZ(_model, GLKMathDegreesToRadians(_rotation.z));
    
    _dirty = NO;
}

#pragma mark setters

- (void) setPosition:(GLKVector3)position
{
    _position = GLKVector3Make(position.x, position.y, position.z-50.0);
    _dirty = YES;
}

- (void) setDest_position:(GLKVector3)position
{
    _dest_position = GLKVector3Make(position.x, position.y, position.z-50.0);
}

- (void) setRotation:(GLKVector3)rotation
{
    _rotation = rotation;
    _dirty = YES;
}

- (void) setScale:(GLKVector3)scale
{
    _scale = scale;
    _dirty = YES;
}

@end
