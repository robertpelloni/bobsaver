#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define SHOT_BLUE 0.0
#define BACKGROUND_BLUE 1.0;
#define SHOT_RADIUS 0.02
#define SHOT_RADIUS_SQUARED SHOT_RADIUS * SHOT_RADIUS
#define DATA_PREV_MOUSE_POS_X 1.0
#define DATA_PREV_MOUSE_POS_Y 1.0
#define EPSILON 0.009
//#define CLEAR
bool about_equal(vec2 a, vec2 b)
{
    return abs(a.x - b.x) < EPSILON && abs(a.y - b.y) < EPSILON;    
}
bool point_in_circle(vec2 point, vec2 circle_center, float radius_squared)
{
    vec2 between = circle_center - point;
    float dist_squared = dot(between, between);
    return radius_squared >= dist_squared;
}
vec2 get_prev_mouse_pos()
{
    return texture2D(backbuffer, vec2(0,0)).ba;
}
vec2 get_mouse_dir()
{
    vec2 dir = mouse - get_prev_mouse_pos();
    if(!about_equal(dir,vec2(0,0)))
       return normalize(dir);
    return vec2(0,0);
}
bool update_if_data_frag()
{
    if(gl_FragCoord.x <= DATA_PREV_MOUSE_POS_X && gl_FragCoord.y <= DATA_PREV_MOUSE_POS_Y)
    {
        glFragColor.rg = mouse;
        glFragColor.ba = texture2D(backbuffer, vec2(0,0)).rg;
        return true;
    }
    return false;
}
vec2 get_shot_dir(vec4 color)
{
    return color.rg * 2.0 - 1.0;
}
vec2 update_shot_helper(vec2 frag_pos, vec2 offset)
{
    vec4 color = texture2D(backbuffer, frag_pos + offset);
    vec2 shot_dir = get_shot_dir(color);
    if(!about_equal(shot_dir, vec2(0.0, 0.0)) && dot(normalize(offset), shot_dir) < 0.71 && color.a > 0.0 )
    {
        return shot_dir;
    }
    return vec2(0,0);
}
void update_shot(vec2 frag_pos)
{
    float offset_x = 1.0 / resolution.x;
    float offset_y = 1.0 / resolution.y;
    vec4 color = texture2D(backbuffer, frag_pos);
    float pressure = color.a;
    vec2 shot_dir = update_shot_helper(frag_pos, vec2(-offset_x,offset_y));
    shot_dir += update_shot_helper(frag_pos, vec2(0,offset_y));
    shot_dir += update_shot_helper(frag_pos, vec2(offset_x,offset_y));
    shot_dir += update_shot_helper(frag_pos, vec2(-offset_x,0));
    shot_dir += update_shot_helper(frag_pos, vec2(offset_x,0));
    shot_dir += update_shot_helper(frag_pos, vec2(-offset_x,-offset_y));
    shot_dir += update_shot_helper(frag_pos, vec2(0,-offset_y));
    shot_dir += update_shot_helper(frag_pos, vec2(offset_x,-offset_y));
    
    if(!about_equal(shot_dir, vec2(0.0, 0.0)))
    {
        glFragColor.b = SHOT_BLUE;
        glFragColor.a = 1.0;
        glFragColor.rg = normalize(shot_dir) * 0.5 + 0.5;
        return;
    }
    glFragColor = color;
    glFragColor.b = BACKGROUND_BLUE;
}
void main( void )
{
    glFragColor = vec4(0.0);
    #ifdef CLEAR
    return;
    #endif
    vec2 aspect = vec2(1.0, resolution.y/resolution.x);
    vec2 frag_pos = gl_FragCoord.xy/resolution;
    vec2 frag_pos_aspect = frag_pos * aspect;
    vec2 mouse_pos_aspect = mouse * aspect;
    vec2 mouse_dir = get_mouse_dir();
    if(update_if_data_frag())
    {
        return;
    }
    if(point_in_circle(frag_pos_aspect, mouse_pos_aspect, SHOT_RADIUS_SQUARED) && !about_equal(mouse_dir, vec2(0,0)))
    {
        glFragColor.b =  SHOT_BLUE;
        glFragColor.rg = get_mouse_dir()*0.5 + 0.5;
        glFragColor.a = 1.0;
    }
    else
    {
        update_shot(frag_pos);
    }

}
