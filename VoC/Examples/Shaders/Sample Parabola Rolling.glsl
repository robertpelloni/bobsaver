#version 420

// original https://www.shadertoy.com/view/ttf3DS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// plotter forked from https://www.shadertoy.com/view/4tB3WV
// demonstration of a catenary being traced by the focus of a parabola rolling on a straight line; https://doi.org/10.4169/074683410x480230

#define BLACK vec3(0.0)
#define WHITE vec3(1.0)

// dark and light colors from Solarized (https://ethanschoonover.com/solarized/)
#define DARK vec3(0., 0.169, 0.212)
#define LIGHT vec3(0.992, 0.965, 0.89)
#define GRAY vec3(0.396, 0.482, 0.514)

// Solarized "accent colors"
#define RED vec3(0.863, 0.196, 0.184)
#define BLUE vec3(0.149, 0.545, 0.824)

// comment out to switch to light mode
#define DARK_MODE

// XY range of the display.
#define DISP_SCALE 8.0 

// Line thickness (in pixels).
#define LINE_SIZE 2.0

// Tick thickness (in pixels).
#define TICK_SIZE 1.0

// Tick length.
#define TICK_LENGTH 0.025 * DISP_SCALE

// Grid line & axis thickness (in pixels).
#define GRID_LINE_SIZE 1.0
#define GRID_AXIS_SIZE 2.0

// Number of grid lines per unit.
#define GRID_LINES 1.0

// graphics primitives

#define drawPrimitive(p, c, d) d = mix(c, d, p)

float POINT(vec2 pt, vec2 p) // pt : position
{
    float psize = 2.5;
    float sc = DISP_SCALE/resolution.y;
    return smoothstep(0.0, 1.1 * sc, distance(pt, p) - psize * sc);
}

float SEGMENT(vec2 a, vec2 b, vec2 p) // a, b : endpoints
{
    vec2 pa = p - a, ba = b - a;
    return smoothstep(0.0, (LINE_SIZE / resolution.y * DISP_SCALE), length(pa - ba * clamp( dot(pa, ba)/dot(ba, ba), 0.0, 1.0 )));
}

// the rolling parabola

float Parabola(float t, vec2 p)
{
        float a = 1.0; // focal length
        vec2 focus = a * vec2(asinh(t), sqrt(1.0 + t * t));
        vec2 direction = a * normalize(vec2(t, 1));
        
        return 2.0 * a + dot(direction, p - focus) - length(p - focus);
}

const vec2 GRADH = vec2(0.01, 0);

// central difference
#define GRAD_PARABOLA(t, p) (0.5 * vec2(Parabola(t, p - GRADH.xy) - Parabola(t, p + GRADH.xy), Parabola(t, p - GRADH.yx) - Parabola(t, p + GRADH.yx)) / GRADH.xx)

// SHOW_PARABOLA(Position, Color, Destination, Screen Position)
#define SHOW_PARABOLA(t, c, d, p) d = mix(c, d, smoothstep(0.0, (LINE_SIZE / resolution.y * DISP_SCALE), abs(Parabola(t, p) / length(GRAD_PARABOLA(t, p)))))

// SHOW_CATENARY(Parameter, Color, Destination, Screen Position)
#define SHOW_CATENARY(a, c, d, p) d = mix(c, d, smoothstep(0.0, (LINE_SIZE / resolution.y * DISP_SCALE), abs((p.y - a * cosh(p.x/a)) / length(vec2(sinh(p.x/a), 1.0)))))

#define MAKETICK(c) (clamp(1.0 + 0.5 * TICK_LENGTH - abs(c), 0.0, 1.0))

float grid(vec2 p, bool showAxes, bool showTicks, bool showGrid)
{
        vec2 uv = mod(p, 1.0 / GRID_LINES);
        float halfScale = 0.5 / GRID_LINES;
    
        float grid = 1.0,  tick = 1.0, axis = 1.0;
        
    if (showTicks) {
        float tickRad = (TICK_SIZE / resolution.y) * DISP_SCALE;
        tick = halfScale - max( MAKETICK(p.y) * abs(uv.x - halfScale), MAKETICK(p.x) * abs(uv.y - halfScale));
        tick = smoothstep(0.0, tickRad, tick);
    }
    
    if (showGrid) {
        float gridRad = (GRID_LINE_SIZE / resolution.y) * DISP_SCALE;
        grid = halfScale - max(abs(uv.x - halfScale), abs(uv.y - halfScale));
        grid = smoothstep(0.0, gridRad, grid);
    }
        
    if (showAxes) {
        float axisRad = (GRID_AXIS_SIZE / resolution.y) * DISP_SCALE;
        axis = min(abs(p.x), abs(p.y));
        axis = smoothstep(axisRad-0.05, axisRad, axis);
    }
        
        return min(tick, min(grid, axis));
}

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
        uv *= DISP_SCALE;
        uv += vec2(0.0, 3.0);
        
        vec3 col = WHITE;
        // set up axes and ticks
        #ifdef DARK_MODE
        col = mix(GRAY, DARK, grid(uv, true, true, false));
        #else
        col = mix(GRAY, LIGHT, grid(uv, true, true, false));
        #endif

        float t = 7.0 * sin(time);
    
        float ast = asinh(t), lt = sqrt(1.0 + t * t);

        drawPrimitive(SEGMENT(vec2(ast, 0.0) + t * vec2(-1.0, t)/lt, vec2(ast, lt), uv), mix(GRAY, WHITE, 0.4), col);
        drawPrimitive(SEGMENT(vec2(ast, 0.0) + vec2(2.0, 1.0 + t * t - 2.0 * t)/lt, vec2(ast, 0.0) + vec2(-2.0, 1.0 + t * t + 2.0 * t)/lt, uv), mix(GRAY, WHITE, 0.4), col);
    
        SHOW_CATENARY(1.0, RED, col, uv);
    
        SHOW_PARABOLA(t, BLUE, col, uv);
    
        drawPrimitive(POINT(vec2(ast, lt), uv), RED, col);
        
        glFragColor = vec4( vec3(col), 1.0 );
}
