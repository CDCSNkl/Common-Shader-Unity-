using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassDisturb : MonoBehaviour
{
    public GameObject player;
    void Update()
    {
        Shader.SetGlobalVector("_PlayerPos", player.transform.position);
    }
}
