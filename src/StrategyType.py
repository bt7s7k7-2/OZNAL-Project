from dataclasses import dataclass, field
from typing import Any, Callable


@dataclass
class StrategyType:
    key: str
    label: str
    factory: Callable | None = None
    parameters: dict[str, Callable[[str], Any]] = field(default_factory=lambda: {})
    auto_assign: bool = True
    callback: Callable[[Any, dict[str, Any]], Any] | None = None
    custom_executor: Callable | None = None
