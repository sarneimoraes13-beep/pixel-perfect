export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      categorias: {
        Row: {
          created_at: string
          id: string
          nome: string
        }
        Insert: {
          created_at?: string
          id?: string
          nome: string
        }
        Update: {
          created_at?: string
          id?: string
          nome?: string
        }
        Relationships: []
      }
      funcionarios: {
        Row: {
          cargo: string | null
          cpf: string | null
          created_at: string
          gh: string
          id: string
          matricula: string
          nome: string
          status: string
          telefone: string | null
          user_id: string | null
        }
        Insert: {
          cargo?: string | null
          cpf?: string | null
          created_at?: string
          gh?: string
          id?: string
          matricula: string
          nome: string
          status?: string
          telefone?: string | null
          user_id?: string | null
        }
        Update: {
          cargo?: string | null
          cpf?: string | null
          created_at?: string
          gh?: string
          id?: string
          matricula?: string
          nome?: string
          status?: string
          telefone?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      itens_operacao: {
        Row: {
          id: string
          material_id: string
          operacao_id: string
          quantidade_devolvida: number
          quantidade_pendente: number | null
          quantidade_retirada: number
        }
        Insert: {
          id?: string
          material_id: string
          operacao_id: string
          quantidade_devolvida?: number
          quantidade_pendente?: number | null
          quantidade_retirada: number
        }
        Update: {
          id?: string
          material_id?: string
          operacao_id?: string
          quantidade_devolvida?: number
          quantidade_pendente?: number | null
          quantidade_retirada?: number
        }
        Relationships: [
          {
            foreignKeyName: "itens_operacao_material_id_fkey"
            columns: ["material_id"]
            isOneToOne: false
            referencedRelation: "materiais"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "itens_operacao_operacao_id_fkey"
            columns: ["operacao_id"]
            isOneToOne: false
            referencedRelation: "operacoes"
            referencedColumns: ["id"]
          },
        ]
      }
      materiais: {
        Row: {
          ativo: boolean
          categoria: string
          codigo: string
          created_at: string
          estoque_atual: number
          estoque_inicial: number
          estoque_minimo: number
          id: string
          nome: string
          unidade: string
        }
        Insert: {
          ativo?: boolean
          categoria?: string
          codigo?: string
          created_at?: string
          estoque_atual?: number
          estoque_inicial?: number
          estoque_minimo?: number
          id?: string
          nome: string
          unidade?: string
        }
        Update: {
          ativo?: boolean
          categoria?: string
          codigo?: string
          created_at?: string
          estoque_atual?: number
          estoque_inicial?: number
          estoque_minimo?: number
          id?: string
          nome?: string
          unidade?: string
        }
        Relationships: []
      }
      movimentacoes: {
        Row: {
          created_at: string
          id: string
          material_id: string
          observacao: string | null
          operacao_id: string | null
          quantidade: number
          tipo: Database["public"]["Enums"]["tipo_movimentacao"]
          usuario_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          material_id: string
          observacao?: string | null
          operacao_id?: string | null
          quantidade: number
          tipo: Database["public"]["Enums"]["tipo_movimentacao"]
          usuario_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          material_id?: string
          observacao?: string | null
          operacao_id?: string | null
          quantidade?: number
          tipo?: Database["public"]["Enums"]["tipo_movimentacao"]
          usuario_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "movimentacoes_material_id_fkey"
            columns: ["material_id"]
            isOneToOne: false
            referencedRelation: "materiais"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "movimentacoes_operacao_id_fkey"
            columns: ["operacao_id"]
            isOneToOne: false
            referencedRelation: "operacoes"
            referencedColumns: ["id"]
          },
        ]
      }
      operacoes: {
        Row: {
          assinatura_devolucao: string | null
          assinatura_retirada: string | null
          created_at: string
          data_devolucao: string | null
          data_retirada: string
          funcionario_id: string
          id: string
          numero_operacao: number
          observacao: string | null
          observacao_devolucao: string | null
          status: Database["public"]["Enums"]["status_operacao"]
          usuario_devolucao: string | null
          usuario_retirada: string | null
        }
        Insert: {
          assinatura_devolucao?: string | null
          assinatura_retirada?: string | null
          created_at?: string
          data_devolucao?: string | null
          data_retirada?: string
          funcionario_id: string
          id?: string
          numero_operacao?: number
          observacao?: string | null
          observacao_devolucao?: string | null
          status?: Database["public"]["Enums"]["status_operacao"]
          usuario_devolucao?: string | null
          usuario_retirada?: string | null
        }
        Update: {
          assinatura_devolucao?: string | null
          assinatura_retirada?: string | null
          created_at?: string
          data_devolucao?: string | null
          data_retirada?: string
          funcionario_id?: string
          id?: string
          numero_operacao?: number
          observacao?: string | null
          observacao_devolucao?: string | null
          status?: Database["public"]["Enums"]["status_operacao"]
          usuario_devolucao?: string | null
          usuario_retirada?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "operacoes_funcionario_id_fkey"
            columns: ["funcionario_id"]
            isOneToOne: false
            referencedRelation: "funcionarios"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          email: string | null
          id: string
          nome: string
        }
        Insert: {
          created_at?: string
          email?: string | null
          id: string
          nome?: string
        }
        Update: {
          created_at?: string
          email?: string | null
          id?: string
          nome?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      _devolucao_core: {
        Args: {
          p_assinatura: string
          p_data: string
          p_itens: Json
          p_obs: string
          p_operacao: string
          p_usuario: string
        }
        Returns: Database["public"]["Enums"]["status_operacao"]
      }
      _retirada_core: {
        Args: {
          p_assinatura: string
          p_data: string
          p_funcionario: string
          p_itens: Json
          p_obs: string
          p_usuario: string
        }
        Returns: string
      }
      ajustar_estoque: {
        Args: { p_delta: number; p_material: string; p_obs: string }
        Returns: undefined
      }
      cancelar_operacao: {
        Args: { p_motivo: string; p_operacao: string }
        Returns: undefined
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_staff: { Args: { _user_id: string }; Returns: boolean }
      listar_usuarios: {
        Args: never
        Returns: {
          email: string
          id: string
          nome: string
          roles: string[]
        }[]
      }
      registrar_devolucao: {
        Args: {
          p_assinatura: string
          p_itens: Json
          p_obs?: string
          p_operacao: string
        }
        Returns: Database["public"]["Enums"]["status_operacao"]
      }
      registrar_retirada: {
        Args: {
          p_assinatura: string
          p_funcionario: string
          p_itens: Json
          p_obs?: string
        }
        Returns: string
      }
    }
    Enums: {
      app_role: "admin" | "operador" | "funcionario"
      status_operacao:
        | "EM_OPERACAO"
        | "DEVOLVIDO"
        | "DEVOLUCAO_PARCIAL"
        | "CANCELADO"
      tipo_movimentacao:
        | "ENTRADA"
        | "RETIRADA"
        | "DEVOLUCAO"
        | "AJUSTE"
        | "CANCELAMENTO"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "operador", "funcionario"],
      status_operacao: [
        "EM_OPERACAO",
        "DEVOLVIDO",
        "DEVOLUCAO_PARCIAL",
        "CANCELADO",
      ],
      tipo_movimentacao: [
        "ENTRADA",
        "RETIRADA",
        "DEVOLUCAO",
        "AJUSTE",
        "CANCELAMENTO",
      ],
    },
  },
} as const
